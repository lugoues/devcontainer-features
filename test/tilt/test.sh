#!/usr/bin/env bash

set -e

source dev-container-features-test-lib

check "tilt version" tilt version

reportResults