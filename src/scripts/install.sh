#!/usr/bin/env bash

# Set smart sudo
if [[ $EUID == 0 ]]; then sudo=""; else sudo="sudo"; fi

# Check if a version is greater than or equal to a given version
version_ge() { test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" == "$1"; }

# Check if a version is less than or equal to a given version
version_le() { test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" == "$1"; }

# Detect platform and architecture
detect_platform() {
  case "$(uname -s)-$(uname -m)" in
  "Darwin-x86_64") echo "macos_x86" ;;
  "Darwin-arm64") echo "macos_arm" ;;
  "Linux-x86_64") echo "linux_x86" ;;
  "Linux-aarch64") echo "linux_arm" ;;
  *) echo "unsupported" ;;
  esac
}

platform="$(detect_platform)"
if [ "$platform" == "unsupported" ]; then
  echo "$(uname -a)-$(uname -m) is not supported. If you believe it should be, please consider opening an issue on the GitHub repository:"
  echo "https://github.com/CircleCI-Public/github-cli-orb"
  exit 1
fi

# If the GH CLI version is less than or equal to 2.24.0 on macOS ARM then exit
# Apple Silicon support was added in 2.25.0
if [[ "$platform" == "macos_arm" ]] && version_le "$PARAM_GH_CLI_VERSION" "2.24.0"; then
  echo "macOS ARM is not supported for GH CLI versions less than or equal to 2.24.0"
  exit 1
fi

# macOS releases after 2.28.0 adopted `.zip`
# More info at https://github.com/cli/cli/releases/tag/v2.28.0
file_extension="tar.gz"
if [[ "$platform" == macos_* ]] && version_ge "$PARAM_GH_CLI_VERSION" "2.28.0"; then
  file_extension="zip"
fi

case "$platform" in
macos_x86)
  download_url="https://github.com/cli/cli/releases/download/v${PARAM_GH_CLI_VERSION}/gh_${PARAM_GH_CLI_VERSION}_macOS_x86_64.$file_extension"
  install_command="$sudo tar -xf ./gh-cli.$file_extension -C /usr/local/ --strip-components=1"
  ;;
macos_arm)
  download_url="https://github.com/cli/cli/releases/download/v${PARAM_GH_CLI_VERSION}/gh_${PARAM_GH_CLI_VERSION}_macOS_arm64.$file_extension"
  install_command="$sudo tar -xf ./gh-cli.$file_extension -C /usr/local/ --strip-components=1"
  ;;
linux_x86)
  download_url="https://github.com/cli/cli/releases/download/v${PARAM_GH_CLI_VERSION}/gh_${PARAM_GH_CLI_VERSION}_linux_amd64.deb"
  install_command="$sudo apt install ./gh-cli.deb"
  file_extension="deb"
  ;;
linux_arm)
  download_url="https://github.com/cli/cli/releases/download/v${PARAM_GH_CLI_VERSION}/gh_${PARAM_GH_CLI_VERSION}_linux_arm64.tar.gz"
  install_command="$sudo tar -xf ./gh-cli.tar.gz -C /usr/local/ --strip-components=1"
  ;;
*)
  echo "This orb does not currently support your platform. If you believe it should, please consider opening an issue on the GitHub repository:"
  echo "https://github.com/CircleCI-Public/github-cli-orb"
  exit 1
  ;;
esac

if command -v gh >/dev/null 2>&1; then
  echo "GH CLI is already installed."
  exit 0
fi

echo "Downloading the GitHub CLI from \"$download_url\"..."
if ! curl -v -sSL "$download_url" -o "gh-cli.$file_extension"; then
  echo "Failed to download GH CLI from $download_url"
  exit 1
fi

echo "Installing the GitHub CLI..."
set -x; $install_command; set +x

echo "Cleaning up..."
rm "gh-cli.$file_extension"

echo "GH CLI installed"
command -v gh
