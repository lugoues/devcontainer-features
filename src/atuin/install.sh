
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
        --option repo='atuinsh/atuin' \
        --option binaryNames='atuin' \
        --option assetRegex='.tar.gz$' \
        --option version="$VERSION"




RC_FILE="/etc/bash.bashrc"
echo "CONFIGUREINIT=${CONFIGUREINIT}" >> "$RC_FILE"
if [ "${CONFIGUREINIT}" = "true" ]; then
    echo 'eval "$(atuin init bash)"' >> "$RC_FILE"
fi
if [ -n "${ATUINHOSTNAME}" ]; then
    echo "export ATUIN_HOST_NAME='${ATUINHOSTNAME}'" >>  "$RC_FILE"
fi

RC_FILE="/etc/zsh/zshrc"
echo "CONFIGUREINIT=${CONFIGUREINIT}" >> "$RC_FILE"
if [ "${CONFIGUREINIT}" = "true" ]; then
    echo 'eval "$(atuin init zsh)"' >> "$RC_FILE"
fi
if [ -n "${ATUINHOSTNAME}" ]; then
    echo "export ATUIN_HOST_NAME='${ATUINHOSTNAME}'" >>  "$RC_FILE"
fi


echo 'Done!'