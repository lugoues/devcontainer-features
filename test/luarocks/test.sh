#!/bin/bash -i

set -e

source dev-container-features-test-lib

check "luarocks --version" luarocks --version

reportResults
