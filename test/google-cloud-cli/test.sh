#!/bin/bash -i

set -e

source dev-container-features-test-lib

check "gcloud version" gcloud version

reportResults