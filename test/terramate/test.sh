#!/usr/bin/env bash


set -e

source dev-container-features-test-lib

check "terramate --version" terramate --version
check "terramate-ls -version" terramate-ls -version

reportResults
