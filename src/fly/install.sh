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

# shellcheck disable=SC2154
$nanolayer_location \
    install \
    devcontainer-feature \
    "ghcr.io/devcontainers-contrib/features/gh-release:1.0.18" \
        --option repo='superfly/flyctl' \
        --option binaryNames='flyctl' \
        --option version="$VERSION"

# Fly is renaming flyctl to fly so we co too
mv "/usr/local/bin/flyctl" "/usr/local/bin/fly"

echo 'Done!'