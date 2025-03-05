#!/usr/bin/env bash


set -e
set -x

source dev-container-features-test-lib


check "kubectl-krew version" kubectl-krew version
check "kubectl-grep  -h" kubectl-grep  -h

reportResults