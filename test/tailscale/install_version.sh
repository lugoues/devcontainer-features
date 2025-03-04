#!/bin/bash -i

set -e
set -x

source dev-container-features-test-lib

check "tailscale version" tailscale version
check "tailscale version == 1.64.2" [ "$(tailscale version 2>/dev/null | head -n1 | cut -d' ' -f4)" == '1.64.2' ]

reportResults