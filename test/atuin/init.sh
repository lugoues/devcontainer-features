#!/usr/bin/env bash


set -e

source dev-container-features-test-lib

check "atuin hostname" atuin --version

check "/etc/bash.bashrc init" grep  -v -q "atuin init" /etc/bash.bashrc
check "/etc/zsh/zshrc init" grep  -v -q "atuin init" /etc/zsh/zshrc

reportResults



