#!/usr/bin/env bash

VERSION=${VERSION:-"latest"}
CADDY_DIR=${CADDY_DIR:-"/usr/local/caddy"}

set -e

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

architecture="$(uname -m)"
if [ "${architecture}" != "amd64" ] && [ "${architecture}" != "x86_64" ] && [ "${architecture}" != "arm64" ] && [ "${architecture}" != "aarch64" ]; then
    echo "(!) Architecture $architecture unsupported"
    exit 1
fi


apt_get_update()
{
    if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
        echo "Running apt-get update..."
        apt-get update -y
    fi
}

# Checks if packages are installed and installs them if not
check_packages() {
    if ! dpkg -s "$@" > /dev/null 2>&1; then
        apt_get_update
        apt-get -y install --no-install-recommends "$@"
    fi
}

# Ensure apt is in non-interactive to avoid prompts
export DEBIAN_FRONTEND=noninteractive

# Install packages
check_packages curl

# Fetch latest version of Hugo if needed
if [ "${VERSION}" = "latest" ] || [ "${VERSION}" = "lts" ]; then
    export VERSION=$(curl -s https://api.github.com/repos/caddyserver/caddy/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4)}')
fi

if ! caddy version &> /dev/null ; then
    echo "Installing Caddy..."
    # Install ARM or x86 version of caddy based on current machine architecture
    arch=$(uname -m)
    if [ "$arch" == "aarch64" ]; then
        arch="arm64"
    fi

    caddy_filename="caddy_${VERSION}_linux_${arch}.tar.gz"
    installation_dir="$CADDY_DIR/bin"
    mkdir -p "$installation_dir"

    caddy_filename="caddy_${VERSION}_linux_${arch}.tar.gz"
    caddy_url="https://github.com/caddyserver/caddy/releases/download/v${VERSION}/${caddy_filename}"
    
    echo "Downloading from ${caddy_url}"
    curl -fsSLO --compressed "$caddy_url"
    tar -xzf "$caddy_filename" -C "$installation_dir"
    rm "$caddy_filename"
fi

echo "Done!"