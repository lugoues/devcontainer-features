#!/usr/bin/env bash


set -e
set -x

source dev-container-features-test-lib

gcloud version
check "gcloud version" gcloud version
check "gcloud version contains gke-gcloud-auth-plugin" bash -c "gcloud version | grep -q gke-gcloud-auth-plugin"

reportResults