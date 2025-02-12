#!/usr/bin/env bash

set_sudo() {
    if [[ $EUID == 0 ]]; then 
        echo ""
    else 
        echo "sudo"
    fi
}

# Function to check if a version is greater than or equal to a given version
version_ge() {
    test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" == "$1"
}

# Function to check if a version is less than or equal to a given version
version_le() {
    test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" == "$1"
}

detect_platform() {
    case "$(uname -s)-$(uname -m)" in
    "Darwin-x86_64") echo "macos_amd64" ;;
    "Darwin-arm64") echo "macos_arm64" ;;
    "Linux-x86_64") echo "linux_amd64" ;;
    "Linux-aarch64") echo "linux_arm64" ;;
    *) echo "unsupported" ;;
    esac
}

download_gh_cli() {
    local platform=$1
    local file_extension=$2
    if [ "$PARAM_GH_CLI_VERSION" = "latest" ]; then
        max_retries=3
        i=0
        while (( i < max_retries )); do
            ((i++))
            LATEST_TAG=$(curl -s https://api.github.com/repos/cli/cli/releases/latest | jq -r '.tag_name')
            if [ "$LATEST_TAG" != null ]; then
                break
            fi
            echo "Couldn't get latest version, retrying..."
            sleep 3
        done
        if (( i == max_retries )); then
            echo "Erro: Max retries exceeded"
            exit 1
        fi

        PARAM_GH_CLI_VERSION="${LATEST_TAG#v}"
    fi
    local download_url="https://github.com/cli/cli/releases/download/v${PARAM_GH_CLI_VERSION}/gh_${PARAM_GH_CLI_VERSION}_${platform}.${file_extension}"
    echo "Downloading the GitHub CLI from \"$download_url\"..."

    if ! curl -sSL "$download_url" -o "gh-cli.$file_extension"; then
        echo "Failed to download GH CLI from $download_url" >&2
        return 1
    fi
}

install_gh_cli() {
    local platform=$1
    local file_extension=$2
    local file_path="gh-cli.$file_extension"

    if [ ! -f "$file_path" ]; then
        echo "Downloaded file $file_path does not exist." >&2
        return 1
    fi

    echo "Installing the GitHub CLI..."
    if [ "$platform" == "linux_amd64" ]; then 
        set -x; $sudo apt install --yes ./"$file_path"; set +x
    else
        set -x; $sudo tar -xf ./"$file_path" -C /usr/local/ --strip-components=1; set +x
    fi
}

sudo=$(set_sudo)

# Check for required commands
for cmd in curl tar; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "Error: $cmd is required. Please install it and try again." >&2
        exit 1
    fi
done

# Verify if the CLI is already installed. Exit if it is.
if command -v gh >/dev/null 2>&1; then
    echo "GH CLI is already installed."
    exit 0
fi

# If the GH CLI version is less than or equal to 2.24.0 on macOS ARM then exit
# Apple Silicon support was added in 2.25.0 (https://github.com/cli/cli/releases/tag/v2.25.0)
if [[ "$platform" == "macos_arm" ]] && version_le "$PARAM_GH_CLI_VERSION" "2.24.0"; then
  echo "You are trying to install version $PARAM_GH_CLI_VERSION. macOS ARM support was added in version 2.25.0, please specify a newer version."
  exit 1
fi

platform=$(detect_platform)
if [ "$platform" == "unsupported" ]; then
    echo "$(uname -a)-$(uname -m) is not supported. If you believe it should be, please consider opening an issue."
    exit 1
fi

# Determine file extension
# macOS releases after 2.28.0 adopted `.zip` (https://github.com/cli/cli/releases/tag/v2.28.0)
file_extension="tar.gz"
if [[ "$platform" == macos_* ]] && version_ge "$PARAM_GH_CLI_VERSION" "2.28.0"; then
    file_extension="zip"
elif [[ "$platform" == "linux_amd64" ]]; then
    file_extension="deb"
fi

# Download and install GH CLI
if ! download_gh_cli "$platform" "$file_extension"; then
    echo "Failed to download the GH CLI."
    exit 1
fi

if ! install_gh_cli "$platform" "$file_extension"; then
    echo "Failed to install the GH CLI."
    exit 1
fi

# Clean up
if ! rm "gh-cli.$file_extension"; then
    echo "Failed to remove the downloaded file."
fi

# Verify installation
if ! command -v gh >/dev/null 2>&1; then
    echo "Something went wrong installing the GH CLI. Please try again or open an issue."
    exit 1
else
    gh --version
fi
