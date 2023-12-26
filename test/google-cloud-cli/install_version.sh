#!/bin/bash -i

set -e
set -x

source dev-container-features-test-lib

check "gcloud version" gcloud version
check "gcloud version == 458.0.0" [ "$(gcloud version 2>/dev/null | head -n1 | cut -d' ' -f4)" == '458.0.0' ]

reportResults