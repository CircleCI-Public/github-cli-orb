#!/usr/bin/env bash
cd "$PARAM_DIR" || exit
additional_args="$(eval printf '%s\\n' "$ORB_EVAL_ADDITIONAL_ARGS")"
files="$(eval printf '%s\\n' "$ORB_EVAL_FILES")"
hostname="$(eval printf '%s' "$ORB_EVAL_HOSTNAME")"
tag="$(eval printf '%s' "$ORB_EVAL_TAG")"
token="${!ORB_ENV_TOKEN}"

[ -z "$token" ] && {
  printf >&2 '%s\n' "A GitHub token must be supplied" "Check the \"token\" parameter."
  exit 1
}
printf '%s\n' "export GITHUB_TOKEN=$token" >>"$BASH_ENV"
[ -n "$hostname" ] && printf '%s\n' "export GITHUB_HOSTNAME=$hostname" >>"$BASH_ENV"

set -x
# shellcheck disable=SC2086
gh release upload \
  "$tag" \
  $files \
  --repo "$(git config --get remote.origin.url)" \
  $additional_args
set +x
