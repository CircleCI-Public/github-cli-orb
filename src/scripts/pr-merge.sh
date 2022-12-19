#!/bin/bash
branch="$(eval printf '%s' "$ORB_EVAL_BRANCH")"
additional_args="$(eval printf '%s\\n' "$ORB_EVAL_ADDITIONAL_ARGS")"
hostname="$(eval printf '%s' "$ORB_EVAL_HOSTNAME")"
token="${!ORB_ENV_TOKEN}"

[ -z "$token" ] && {
  printf >&2 '%s\n' "A GitHub token must be supplied" "Check the \"token\" parameter."
  exit 1
}
printf '%s\n' "export GITHUB_TOKEN=$token" >>"$BASH_ENV"
[ -n "$hostname" ] && printf '%s\n' "export GITHUB_HOSTNAME=$hostname" >>"$BASH_ENV"

set -x
# shellcheck disable=SC2086
gh pr merge \
  $branch --repo "$(git config --get remote.origin.url)" \
  $additional_args
set +x
