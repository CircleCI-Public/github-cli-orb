#!/bin/bash
# Ensure known hosts are entered. Required for Docker.
mkdir -p ~/.ssh

ssh-keyscan -t rsa "$PARAM_GH_HOSTNAME" >> ~/.ssh/known_hosts

PARAM_GITHUB_REPO_EXPANDED="$(eval echo "$PARAM_GH_REPO")"

if [ -n "$PARAM_BRANCH"]; then
    PARAM_BRANCH="-- --branch=$PARAM_BRANCH"
fi

gh repo clone "$PARAM_GITHUB_REPO_EXPANDED" "$PARAM_GH_DIR" "$PARAM_BRANCH"
