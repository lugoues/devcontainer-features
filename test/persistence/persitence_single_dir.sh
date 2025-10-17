#!/bin/bash

set -e

source dev-container-features-test-lib

# from scenario
source="/mnt/persistence-data"
home="/home/vscode"


check "source exists" test -d "${source}"
check "target symlink" test -L "${home}/.config/tests/nested/deep"
check "write test file to new linked dir" touch "${home}/.config/tests/nested/deep/test_file"
check "ensure it exists in target" test -f "${source}/home_vscode_.config_tests_nested_deep/test_file"
check "ensure user owns target" bash -xc "[[ \$(stat -c '%U' ${source}/home_vscode_.config_tests_nested_deep/test_file) == vscode ]]"

reportResults
