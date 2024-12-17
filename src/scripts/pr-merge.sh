#!/bin/bash
branch="$(eval printf '%s' "$ORB_EVAL_BRANCH")"
readarray -t additional_args < <(eval "set -- $ORB_EVAL_ADDITIONAL_ARGS; printf '%s\n' \"\$@\"")
hostname="$(eval printf '%s' "$ORB_EVAL_HOSTNAME")"
repo="$(eval printf '%s' "$ORB_EVAL_REPO")"
token="${!ORB_ENV_TOKEN}"

[ -z "$token" ] && {
  printf >&2 '%s\n' "A GitHub token must be supplied" "Check the \"token\" parameter."
  exit 1
}
printf '%s\n' "export GITHUB_TOKEN=$token" >>"$BASH_ENV"
[ -n "$hostname" ] && printf '%s\n' "export GITHUB_HOSTNAME=$hostname" >>"$BASH_ENV"
[ -n "$repo" ] && repo="-R $repo"

set -x
# shellcheck disable=SC2086
gh pr merge \
  $branch $repo \
  "${additional_args[@]}"
set +x
