#!/bin/bash -i

set -e

source ./library_scripts.sh

# nanolayer is a cli utility which keeps container layers as small as possible
# source code: https://github.com/devcontainers-contrib/nanolayer
# `ensure_nanolayer` is a bash function that will find any existing nanolayer installations,
# and if missing - will download a temporary copy that automatically get deleted at the end
# of the script
ensure_nanolayer nanolayer_location "v0.5.4"

 #shellcheck disable=SC2154
$nanolayer_location \
    install \
    devcontainer-feature \
    "ghcr.io/devcontainers-contrib/features/gh-release:1.0.18" \
    --option repo='atuinsh/atuin' --option libName='atuin' --option binaryNames='atuin' --option version="$VERSION"

if [[ "$(cat /etc/bash.bashrc)" != *"$1"* ]]; then
    echo "Updating /etc/bash.bashrc"
     #shellcheck disable=SC2016
    echo 'eval "$(atuin init bash)"' >>/etc/bash.bashrc

    mkdir -p /usr/local/share/bash-preexec
    curl https://raw.githubusercontent.com/rcaloras/bash-preexec/master/bash-preexec.sh -o /usr/local/share/bash-preexec/.bash-tc.sh
    printf '\n[[ -f /usr/local/share/bash-preexec/.bash-tc.sh ]] && source /usr/local/share/bash-preexec/.bash-tc.sh\n' >> ~/.bashrc
fi

if [ -f "/etc/zsh/zshrc" ] && [[ "$(cat /etc/zsh/zshrc)" != *"$1"* ]]; then
    echo "Updating /etc/zsh/zshrc"
    #shellcheck disable=SC2016
    echo 'eval "$(atuin init zsh)"' >>/etc/zsh/zshrc
fi

echo 'Done!'