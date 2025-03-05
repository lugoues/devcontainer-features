#!/usr/bin/env bash


set -e

source dev-container-features-test-lib

check "lnav --version" lnav --version

reportResults
