#!/bin/bash
# Get auth token
[ -z "${!PARAM_GH_TOKEN}" ] && echo "A GitHub token must be supplied. Check the \"token\" parameter." && exit 1

if [[ "${PARAM_GH_HOSTNAME}" == "github.com" ]]; then
    export GITHUB_TOKEN=${!PARAM_GH_TOKEN}
    echo "export GITHUB_TOKEN=\"${GITHUB_TOKEN}\"" >> "$BASH_ENV"
else
    export GH_ENTERPRISE_TOKEN=${!PARAM_GH_TOKEN}
    echo "export GH_ENTERPRISE_TOKEN=\"${GH_ENTERPRISE_TOKEN}\"" >> "$BASH_ENV"
    export GH_HOST=${PARAM_GH_HOSTNAME}
    echo "export GH_HOST=\"${PARAM_GH_HOSTNAME}\"" >> "$BASH_ENV"
fi

# Setup git with GH CLI
echo
echo "Setting up git with GH CLI"
gh auth setup-git --hostname "$PARAM_GH_HOSTNAME"

echo
echo "Viewing authentication GH authentication status"
gh auth status || echo "Viewing auth status is unavailable without proper scope."

# Configure
echo
echo "Disabling interactive prompts for GH CLI"
gh config set prompt disabled
