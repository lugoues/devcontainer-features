#!/bin/bash

set -e

source dev-container-features-test-lib

# from scenario
source="/mnt/persistence-data"
home="/home/vscode"

# Directory bind: ~/.config/bindtest did not exist in the image
check "dir is a mountpoint" mountpoint -q "${home}/.config/bindtest"
check "dir is not a symlink" bash -c "[[ ! -L ${home}/.config/bindtest ]]"
check "write through bind dir" touch "${home}/.config/bindtest/test_file"
check "write lands in volume" test -f "${source}/home_vscode_.config_bindtest/test_file"
check "user owns dir" bash -c "[[ \$(stat -c '%U' ${home}/.config/bindtest) == vscode ]]"

# File bind: ~/.bashrc ships with the base image, so it must be seeded
check "file is a mountpoint" mountpoint -q "${home}/.bashrc"
check "file seeded" test -s "${source}/home_vscode_.bashrc"
check "content matches through mount" cmp -s "${home}/.bashrc" "${source}/home_vscode_.bashrc"
check "user owns file" bash -c "[[ \$(stat -c '%U' ${source}/home_vscode_.bashrc) == vscode ]]"

# The mountpoint survives what kills a symlink: delete-and-recreate semantics.
# rmdir/unlink on a mountpoint must fail with EBUSY.
check "dir mountpoint cannot be removed" bash -c "! rmdir ${home}/.config/bindtest 2>/dev/null"

# Idempotency: re-running post-start (simulates a container restart) must not
# fail, must not double-mount, and must not re-seed.
check "markers recorded" bash -c "test -e ${source}/.persistence-init/home_vscode_.config_bindtest && test -e ${source}/.persistence-init/home_vscode_.bashrc"
check "truncate persisted file" bash -c ": >| ${home}/.bashrc"
check "re-run post-start" /usr/local/share/persistence_post_start
check "still exactly one mount" bash -c "[[ \$(grep -c ${home}/.config/bindtest /proc/mounts) -eq 1 ]]"
check "truncated file not re-seeded" bash -c "[[ ! -s ${source}/home_vscode_.bashrc ]]"

reportResults
