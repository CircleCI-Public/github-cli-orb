#!/bin/bash
# Get auth token
export GITHUB_TOKEN=${!PARAM_GH_TOKEN}
[ -z "$GITHUB_TOKEN" ] && echo "A GitHub token must be supplied. Check the \"token\" parameter." && exit 1
echo "export GITHUB_TOKEN=\"${GITHUB_TOKEN}\"" >> "$BASH_ENV"

# Authenticate
echo
echo "Authenticating GH CLI"
gh auth setup-git --hostname "$PARAM_GH_HOSTNAME"
gh auth status

# Configure
echo
echo "Disabling interactive prompts for GH CLI"
gh config set prompt disabled
