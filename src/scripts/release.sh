#!/bin/bash
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

gh release create "$PARAM_GH_TAG" "$@" "$PARAM_GH_FILES"