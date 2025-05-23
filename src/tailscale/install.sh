#!/usr/bin/env bash

set -e

source ./library_scripts.sh

# nanolayer is a cli utility which keeps container layers as small as possible
# source code: https://github.com/devcontainers-extra/nanolayer
# `ensure_nanolayer` is a bash function that will find any existing nanolayer installations,
# and if missing - will download a temporary copy that automatically get deleted at the end
# of the script
ensure_nanolayer nanolayer_location "v0.5.6"


$nanolayer_location \
    install \
    devcontainer-feature \
    "ghcr.io/devcontainers-extra/features/curl-apt-get:1.0.16"



curl -fsSL https://tailscale.com/install.sh | sh


if [ ! -e "/usr/local/share/tailscaled-entrypoint.sh" ]; then
    echo "(*) Setting up entrypoint..."
    cp -f tailscaled-entrypoint.sh /usr/local/share/
    chmod +x /usr/local/share/tailscaled-entrypoint.sh
fi