#!/bin/bash
# set smart sudo
if [[ $EUID == 0 ]]; then export SUDO=""; else export SUDO="sudo"; fi

# Define current platform
if [[ "$(uname -s)" == "Darwin" && "$(uname -m)" == "x86_64" ]]; then
	export SYS_ENV_PLATFORM=macos
elif [[ "$(uname -s)" == "Darwin" && "$(uname -m)" == "arm64" ]]; then
	export SYS_ENV_PLATFORM=macos_arm
elif [[ "$(uname -s)" == "Linux" && "$(uname -m)" == "x86_64" ]]; then
	export SYS_ENV_PLATFORM=linux_x86
elif [[ "$(uname -s)" == "Linux" && "$(uname -m)" == "aarch64" ]]; then
	export SYS_ENV_PLATFORM=linux_arm
else
	echo "This platform appears to be unsupported."
	uname -a
	exit 1
fi

download_gh_binary() {
  local release="$1"
  local output="$2"
  set -x
  curl -sSL "https://github.com/cli/cli/releases/download/v${PARAM_GH_CLI_VERSION}/gh_${PARAM_GH_CLI_VERSION}_${release}" -o "$output"
  set +x
}

# If not installed
if ! command -v gh >/dev/null 2>&1; then
	echo "Installing the GitHub CLI"
	case $SYS_ENV_PLATFORM in
	linux_x86)
    	download_gh_binary "linux_amd64.deb" "gh-cli.deb"
		$SUDO apt install ./gh-cli.deb
		rm gh-cli.deb
		;;
	macos_arm)
    	download_gh_binary "macOS_arm64.tar.gz" "gh-cli.tar.gz"
		$SUDO tar -xf ./gh-cli.tar.gz -C /usr/local/ --strip-components=1
		rm gh-cli.tar.gz
		;;
	macos)
    	download_gh_binary "macOS_amd64.tar.gz" "gh-cli.tar.gz"
		$SUDO tar -xf ./gh-cli.tar.gz -C /usr/local/ --strip-components=1
		rm gh-cli.tar.gz
		;;
	linux_arm)
    	download_gh_binary "linux_arm64.tar.gz" "gh-cli.tar.gz"
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
