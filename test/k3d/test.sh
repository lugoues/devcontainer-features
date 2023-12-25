#!/bin/bash -i

set -e

source dev-container-features-test-lib

check "k3d version" k3d version

reportResults