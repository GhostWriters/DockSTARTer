#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

run_yum() {
    if [[ ${CI:-} != true ]] && [[ ${TRAVIS:-} != true ]]; then
        info "Upgrading packages."
        yum -y upgrade > /dev/null 2>&1
    fi
    info "Installing dependencies."
    yum -y install curl git grep newt sed > /dev/null 2>&1
    info "Removing unused packages."
    yum -y autoremove > /dev/null 2>&1
    info "Cleaning up package cache."
    yum -y clean all > /dev/null 2>&1
}
