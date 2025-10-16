#!/bin/bash

set -ex

source dev-container-features-test-lib

# from scenario
source="/mnt/persistence_data"
home="/home/vscode"

check "source exists" test -d "${source}"
check "target symlink" test -L "${home}/.config/tests"
check "write test file to new linked dir" touch "${home}/.config/tests/test_file"
check "ensure it exists in target" test -f "${source}/home_vscode_.config_tests/test_file"
check "ensure user owns target" bash -xc "[[ \$(stat -c '%U' ${source}/home_vscode_.config_tests/test_file) == vscode ]]"

reportResults
