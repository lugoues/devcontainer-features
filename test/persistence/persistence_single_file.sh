#!/bin/bash

set -ex

source dev-container-features-test-lib

# from scenario
source="/mnt/persistence-data"
home="/home/vscode"
string="testing"

check "source exists" test -d "${source}"
check "target symlink" test -L "${home}/.zshrc"
check "write test file to new linked dir" bash -xc "echo ${string} >| ${home}/.zshrc"
check "ensure it exists in target" bash -xc "[[ \$(cat ${source}/home_vscode_.zshrc) == ${string} ]]"
check "ensure user owns target" bash -xc "[[ \$(stat -c '%U' ${source}/home_vscode_.zshrc) == vscode ]]"

reportResults
