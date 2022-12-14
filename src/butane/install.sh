#!/usr/bin/env bash

VERSION=${VERSION:-"latest"}

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
    export VERSION=$(curl -s https://api.github.com/repos/coreos/butane/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4)}')
fi

echo "Installing Butane..."
arch=$(uname -m)

butane_filename="butane-${arch}-unknown-linux-gnu"
butane_url="https://github.com/coreos/butane/releases/download/v${VERSION}/${butane_filename}"

echo "Downloading from ${butane_url}"
cd /tmp
curl -fsSLO --compressed "$butane_url"
mv $butane_filename /usr/local/bin/butane
chmod +x /usr/local/bin/butane

echo "Done!"