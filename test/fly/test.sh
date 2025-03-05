#!/usr/bin/env bash


set -e

source dev-container-features-test-lib

check "fly version" fly version

reportResults