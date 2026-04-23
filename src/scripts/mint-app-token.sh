#!/bin/bash
# shellcheck disable=SC2016
set -euo pipefail

# Ensure required tools are available. These are commonly present on cimg/*
# images but not guaranteed on bare machine executors or alpine-based images.
need=()
for bin in jq openssl curl; do
    command -v "$bin" >/dev/null 2>&1 || need+=("$bin")
done
if [ "${#need[@]}" -gt 0 ]; then
    if command -v apt-get >/dev/null 2>&1; then
        SUDO=""
        [ "$(id -u)" -ne 0 ] && SUDO="sudo"
        $SUDO apt-get update -qq
        $SUDO apt-get install -y -qq "${need[@]}" >/dev/null
    elif command -v apk >/dev/null 2>&1; then
        apk add --no-cache "${need[@]}" >/dev/null
    elif command -v yum >/dev/null 2>&1; then
        SUDO=""
        [ "$(id -u)" -ne 0 ] && SUDO="sudo"
        $SUDO yum install -y "${need[@]}" >/dev/null
    else
        echo "Missing required tools (${need[*]}) and no supported package manager (apt-get/apk/yum) was found." >&2
        exit 1
    fi
fi

APP_ID_VAL="${!PARAM_APP_ID:-}"
PRIVATE_KEY_VAL="${!PARAM_PRIVATE_KEY:-}"
INSTALL_ID_VAL="${!PARAM_INSTALLATION_ID:-}"

if [ -z "$APP_ID_VAL" ]; then
    echo "App ID env var '$PARAM_APP_ID' is empty. Set it on the job context." >&2
    exit 1
fi
if [ -z "$PRIVATE_KEY_VAL" ]; then
    echo "Private key env var '$PARAM_PRIVATE_KEY' is empty. Set it on the job context." >&2
    exit 1
fi

OWNER="$(eval printf '%s' "$PARAM_INSTALLATION_OWNER")"
REPO="$(eval printf '%s' "$PARAM_INSTALLATION_REPO")"

if [ "$PARAM_HOSTNAME" = "github.com" ]; then
    API="https://api.github.com"
else
    API="https://${PARAM_HOSTNAME}/api/v3"
fi

# Accept either a raw PEM (possibly with literal "\n") or a base64-encoded PEM.
# CircleCI contexts render awkwardly for multi-line values, so base64 is a
# common way teams store App private keys.
PEM="$(mktemp)"
chmod 600 "$PEM"
trap 'rm -f "$PEM"' EXIT
if printf '%s' "$PRIVATE_KEY_VAL" | grep -q "BEGIN"; then
    printf '%s' "$PRIVATE_KEY_VAL" | sed 's/\\n/\n/g' > "$PEM"
else
    printf '%s' "$PRIVATE_KEY_VAL" | tr -d '[:space:]' | base64 -d > "$PEM"
fi

b64url() { openssl base64 -A | tr '+/' '-_' | tr -d '='; }

now=$(date +%s)
header="$(printf '{"alg":"RS256","typ":"JWT"}' | b64url)"
# iat -60s to tolerate clock skew; exp +9m is the max allowed by GitHub.
payload="$(printf '{"iat":%d,"exp":%d,"iss":"%s"}' "$((now - 60))" "$((now + 540))" "$APP_ID_VAL" | b64url)"
sig="$(printf '%s' "${header}.${payload}" | openssl dgst -sha256 -sign "$PEM" -binary | b64url)"
JWT="${header}.${payload}.${sig}"

# Intentionally no `set -x` anywhere in this script: the JWT and the minted
# token are both sensitive and must never land in build logs.

AUTH_HEADER="Authorization: Bearer $JWT"
ACCEPT_HEADER="Accept: application/vnd.github+json"

if [ -z "$INSTALL_ID_VAL" ]; then
    if [ -n "$REPO" ]; then
        INSTALL_ID_VAL="$(curl -sSf \
            -H "$AUTH_HEADER" \
            -H "$ACCEPT_HEADER" \
            "$API/repos/$OWNER/$REPO/installation" | jq -r .id)"
    else
        INSTALL_ID_VAL="$(curl -sSf \
            -H "$AUTH_HEADER" \
            -H "$ACCEPT_HEADER" \
            "$API/orgs/$OWNER/installation" | jq -r .id)"
    fi
fi

if [ -z "$INSTALL_ID_VAL" ] || [ "$INSTALL_ID_VAL" = "null" ]; then
    echo "Could not resolve a GitHub App installation id for owner=$OWNER repo=$REPO." >&2
    echo "Either install the App on that target, or set the env var named by 'installation_id'." >&2
    exit 1
fi

# Build the POST body. Only include "permissions" / "repositories" when the
# caller provided them; sending empty values would 422 from the API.
BODY="{}"
if [ -n "$PARAM_PERMISSIONS" ] && [ -n "$PARAM_REPOSITORIES" ]; then
    BODY="$(jq -cn \
        --argjson perms "$PARAM_PERMISSIONS" \
        --argjson repos "$PARAM_REPOSITORIES" \
        '{permissions: $perms, repositories: $repos}')"
elif [ -n "$PARAM_PERMISSIONS" ]; then
    BODY="$(jq -cn --argjson perms "$PARAM_PERMISSIONS" '{permissions: $perms}')"
elif [ -n "$PARAM_REPOSITORIES" ]; then
    BODY="$(jq -cn --argjson repos "$PARAM_REPOSITORIES" '{repositories: $repos}')"
fi

TOKEN="$(curl -sSf -X POST \
    -H "$AUTH_HEADER" \
    -H "$ACCEPT_HEADER" \
    -H "Content-Type: application/json" \
    -d "$BODY" \
    "$API/app/installations/$INSTALL_ID_VAL/access_tokens" | jq -r .token)"

if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
    echo "Failed to mint installation access token." >&2
    exit 1
fi

# Export the minted token into $BASH_ENV so subsequent steps can consume it.
# Downstream `gh/setup` reads the env var named by its `token` parameter, so
# setting `export_as` to that same name (default GITHUB_TOKEN) makes the App
# path transparent to the rest of the orb.
printf 'export %s=%s\n' "$PARAM_EXPORT_AS" "$TOKEN" >> "$BASH_ENV"

echo "Minted GitHub App installation token (installation id=$INSTALL_ID_VAL) and exported as \$$PARAM_EXPORT_AS."
