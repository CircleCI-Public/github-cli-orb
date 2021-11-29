#!/bin/bash
# set smart sudo
if [[ $EUID == 0 ]]; then export SUDO=""; else export SUDO="sudo"; fi

# Define current platform
if [[ "$(uname -s)" == "Darwin" && "$(uname -m)" == "x86_64" ]]; then
	export SYS_ENV_PLATFORM=macos
elif [[ "$(uname -s)" == "Linux" && "$(uname -m)" == "x86_64" ]]; then
	export SYS_ENV_PLATFORM=linux_x86
elif [[ "$(uname -s)" == "Linux" && "$(uname -m)" == "aarch64" ]]; then
	export SYS_ENV_PLATFORM=linux_arm
else
	echo "This platform appears to be unsupported."
	uname -a
	exit 1
fi

# If not installed
if ! command -v gh >/dev/null 2>&1; then
	echo "Installing the GitHub CLI"
	case $SYS_ENV_PLATFORM in
		linux_x86)
			curl -sSL "https://github.com/cli/cli/releases/download/v${PARAM_GH_CLI_VERSION}/gh_${PARAM_GH_CLI_VERSION}_linux_amd64.deb" -o "gh-cli.deb"
			$SUDO apt install ./gh-cli.deb
			rm gh-cli.deb
			;;
		macos)
			curl -sSL "https://github.com/cli/cli/releases/download/v${PARAM_GH_CLI_VERSION}/gh_${PARAM_GH_CLI_VERSION}_macOS_amd64.tar.gz" -o "gh-cli.tar.gz"
			$SUDO tar -xf ./gh-cli.tar.gz -C /usr/local/ --strip-components=1
			rm gh-cli.tar.gz
			;;
		linux_arm)
			curl -sSL "https://github.com/cli/cli/releases/download/v${PARAM_GH_CLI_VERSION}/gh_${PARAM_GH_CLI_VERSION}_linux_arm64.tar.gz" -o "gh-cli.tar.gz"
			$SUDO tar -xf ./gh-cli.tar.gz -C /usr/local/ --strip-components=1
			rm gh-cli.tar.gz
			;;
		*)
		echo "This orb does not currently support your platform. If you believe it should, please consider opening an issue on the GitHub repository:"
		echo "https://github.com/CircleCI-Public/github-cli-orb"
		exit 1
	;;
	esac
	# Validate install.
	echo
	echo "GH CLI installed"
	command -v gh
else
	echo "GH CLI is already installed."
fi
