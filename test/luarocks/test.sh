#!/usr/bin/env bash


set -e

source dev-container-features-test-lib

check "luarocks --version" luarocks --version

reportResults
