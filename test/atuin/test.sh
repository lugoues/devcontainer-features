#!/usr/bin/env bash


set -e

source dev-container-features-test-lib

check "atuin --version" atuin --version

check "/etc/bash.bashrc hostname" grep -v -q "export ATUIN_HOST_NAME" /etc/bash.bashrc
check "/etc/zsh/zshrc hostname" grep -v -q "export ATUIN_HOST_NAME" /etc/zsh/zshrc

check "/etc/bash.bashrc init"  grep -q "atuin init" /etc/bash.bashrc
check "/etc/zsh/zshrc init" grep -q "atuin init" /etc/zsh/zshrc


reportResults
