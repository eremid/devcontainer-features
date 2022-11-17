#!/usr/bin/env bash

VERSION=${VERSION:-"latest"}

set -e

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
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

curl -O https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh
chmod +x install_kustomize.sh

if [ "${VERSION}" != "latest" ]
then
    ./install_kustomize.sh $VERSION /usr/local/bin
else
    ./install_kustomize.sh /usr/local/bin
fi

echo "Done!"