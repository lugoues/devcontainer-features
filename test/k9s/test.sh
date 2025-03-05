#!/usr/bin/env bash


set -e

source dev-container-features-test-lib

check "k9s version" k9s version

reportResults