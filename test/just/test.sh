#!/bin/bash -i

set -e

source dev-container-features-test-lib

check "just --version" just --version
check "bash test" bash -i -c "exit"
check "zsh test" zsh -i -c "exit"

reportResults
