#!/bin/bash

set -e

source dev-container-features-test-lib

# from scenario
source="/mnt/persistence-data"
home="/home/vscode"

# ~/.bashrc ships with the base image, so this exercises the migration path:
# original moved to .backup, volume seeded from it on first create.
check "target symlink" test -L "${home}/.bashrc"
check "backup exists" test -f "${home}/.bashrc.backup"
check "volume file seeded" test -s "${source}/home_vscode_.bashrc"
check "seed matches backup" cmp -s "${home}/.bashrc.backup" "${source}/home_vscode_.bashrc"
check "content readable through symlink" cmp -s "${home}/.bashrc" "${home}/.bashrc.backup"
check "ensure user owns target" bash -c "[[ \$(stat -c '%U' ${source}/home_vscode_.bashrc) == vscode ]]"

# Marker semantics: once initialized, intentionally truncated data must not be
# re-seeded from the image-layer backup (simulates a rebuild by re-running the
# post-create script against the existing volume).
check "init marker recorded" test -e "${source}/.persistence-init/home_vscode_.bashrc"
check "truncate persisted file" bash -c ": >| ${home}/.bashrc"
check "re-run post-create" /usr/local/share/persistence_post_create
check "truncated file not re-seeded" bash -c "[[ ! -s ${source}/home_vscode_.bashrc ]]"

reportResults
