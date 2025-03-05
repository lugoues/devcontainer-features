#!/usr/bin/env bash


set -e

source dev-container-features-test-lib

check "atuin hostname" atuin --version

check "/etc/bash.bashrc hostname" grep -q "export ATUIN_HOST_NAME='testing-host'" /etc/bash.bashrc
check "/etc/zsh/zshrc hostname" grep -q "export ATUIN_HOST_NAME='testing-host'" /etc/zsh/zshrc

reportResults



