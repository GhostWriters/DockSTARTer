#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

run_yum() {
    if [[ ${CI:-} != true ]] && [[ ${TRAVIS:-} != true ]]; then
        info "Upgrading packages."
        yum -y upgrade > /dev/null 2>&1 || fatal "Failed to upgrade packages from yum."
    fi
    info "Installing dependencies."
    yum -y install curl git grep newt rsync sed > /dev/null 2>&1 || fatal "Failed to install dependencies from yum."
    info "Removing unused packages."
    yum -y autoremove > /dev/null 2>&1 || fatal "Failed to remove unused packages from yum."
    info "Cleaning up package cache."
    yum -y clean all > /dev/null 2>&1 || fatal "Failed to cleanup cache from yum."
}
