#!/bin/bash -i

set -e

# shellcheck disable=SC1091
source ./library_scripts.sh

# nanolayer is a cli utility which keeps container layers as small as possible
# source code: https://github.com/devcontainers-contrib/nanolayer
# `ensure_nanolayer` is a bash function that will find any existing nanolayer installations,
# and if missing - will download a temporary copy that automatically get deleted at the end
# of the script
ensure_nanolayer nanolayer_location "v0.5.4"

updaterc() {

	if cat /etc/os-release | grep "ID_LIKE=.*alpine.*\|ID=.*alpine.*" ; then
		echo "Updating /etc/profile"
		echo -e "${1//\$SHELL/sh}" >>/etc/profile
	fi
	if [[ "$(cat /etc/bash.bashrc)" != *"$1"* ]]; then
		echo "Updating /etc/bash.bashrc"
		echo -e "$1" >>/etc/bash.bashrc
	fi
	if [ -f "/etc/zsh/zshrc" ] && [[ "$(cat /etc/zsh/zshrc)" != *"$1"* ]]; then
		echo "Updating /etc/zsh/zshrc"
		echo -e "$1" >>/etc/zsh/zshrc
	fi
}

# shellcheck disable=SC2154
$nanolayer_location \
    install \
    devcontainer-feature \
    "ghcr.io/devcontainers-contrib/features/gh-release:1.0.18" \
        --option repo='casey/just'  \
        --option binaryNames='just' \
        --option libName='just'     \
        --option version="$VERSION"

echo "Installing completions"

mkdir -p /usr/local/share/just/completions/
/usr/local/bin/just --completions zsh > /usr/local/share/just/completions/just.zsh
/usr/local/bin/just --completions bash > /usr/local/share/just/completions/just.bash
/usr/local/bin/just --completions fish > /usr/local/share/just/completions/just.fish

if [[ "$(cat /etc/bash.bashrc)" != *"$1"* ]]; then
    echo "Updating /etc/bash.bashrc"
    echo -e ". /usr/local/share/just/completions/just.bash" >>/etc/bash.bashrc
fi

if [ -f "/etc/zsh/zshrc" ] && [[ "$(cat /etc/zsh/zshrc)" != *"$1"* ]]; then
    echo "Updating /etc/zsh/zshrc"
    echo -e ". fpath=(/usr/local/share/just/completions/just.zsh \$fpath)" >>/etc/zsh/zshrc
fi

echo 'Done!'