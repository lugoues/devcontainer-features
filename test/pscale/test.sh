#!/usr/bin/env bash


set -e

source dev-container-features-test-lib

check "pscale version" pscale version

reportResults