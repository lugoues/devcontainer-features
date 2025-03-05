#!/usr/bin/env bash

set -e

. ./library_scripts.sh

# nanolayer is a cli utility which keeps container layers as small as possible
# source code: https://github.com/devcontainers-extra/nanolayer
# `ensure_nanolayer` is a bash function that will find any existing nanolayer installations,
# and if missing - will download a temporary copy that automatically get deleted at the end
# of the script
ensure_nanolayer nanolayer_location "v0.5.6"


$nanolayer_location \
    install \
    devcontainer-feature \
    "ghcr.io/devcontainers-extra/features/gh-release:1.0.25" \
    --option repo="jdx/mise" \
    --option binaryNames="mise" \
    --option version="$VERSION" \
    --option assetRegex='.tar.gz$'

function updaterc {
	if [[ "$(cat /etc/bash.bashrc)" != *'eval "$(/usr/local/bin/mise activate bash)"'* ]]; then
		echo "Updating /etc/bash.bashrc"
		echo 'eval "$(/usr/local/bin/mise activate bash)"' >>/etc/bash.bashrc
	fi

	if [ -f "/etc/zsh/zshrc" ] && [[ "$(cat /etc/zsh/zshrc)" != *'eval "$(/usr/local/bin/mise activate zsh)"'* ]]; then
		echo "Updating /etc/zsh/zshrc"
		echo 'eval "$(/usr/local/bin/mise activate zsh)"' >>/etc/zsh/zshrc
	fi
}

updaterc

echo 'Done!'