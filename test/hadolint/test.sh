#!/usr/bin/env bash


set -e

source dev-container-features-test-lib

check "hadolint version" hadolint --version

reportResults