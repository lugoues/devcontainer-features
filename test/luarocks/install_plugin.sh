#!/bin/bash -i

set -e
set -x

source dev-container-features-test-lib


check "luarocks --version" luarocks --version
check "luarocks list | grep fennel" bash -c "luarocks list | grep fennel"


reportResults