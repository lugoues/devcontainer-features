#!/usr/bin/env bash


set -e

source dev-container-features-test-lib

check "gcloud version" gcloud version

reportResults