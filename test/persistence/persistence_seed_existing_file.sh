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

reportResults
