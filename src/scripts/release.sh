#!/bin/bash
# Get auth token
set -x
cd "$PARAM_DIR" || exit
export GITHUB_TOKEN=${!PARAM_GH_TOKEN}
[ -z "$GITHUB_TOKEN" ] && echo "A GitHub token must be supplied. Check the \"token\" parameter." && exit 1
echo "export GITHUB_TOKEN=\"${GITHUB_TOKEN}\"" >>"$BASH_ENV"

# Get hostname if set
if [ "$PARAM_GH_HOSTNAME" == 1 ]; then
	export GITHUB_HOSTNAME=${!PARAM_GH_HOSTNAME}
	echo "export GITHUB_HOSTNAME=\"${PARAM_GH_HOSTNAME}\"" >>"$BASH_ENV"
fi
set -- "$@" --repo "$(git config --get remote.origin.url)"

if [ "$PARAM_GH_DRAFT" == 1 ]; then
	set -- "$@" --draft
fi
if [ "$PARAM_GH_PRERELEASE" == 1 ]; then
	set -- "$@" --prerelease
fi
if [ -n "$PARAM_GH_NOTES" ]; then
	set -- "$@" --notes-file "$PARAM_GH_NOTES"
fi
if [ -n "$PARAM_GH_TITLE" ]; then
	set -- "$@" --title "$PARAM_GH_TITLE"
fi
if [ -n "$PARAM_GH_FILES" ]; then
	set -- "$@" "$PARAM_GH_FILES"
fi
  
# shellcheck disable=SC2086
gh release create \
  "$PARAM_GH_TAG" \
  "$PARAM_GH_ARGS" \
  $@
set +x