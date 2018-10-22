#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

run_dnf() {
    if [[ ${CI:-} != true ]] && [[ ${TRAVIS:-} != true ]]; then
        info "Upgrading packages."
        dnf -y upgrade --refresh > /dev/null 2>&1 || fatal "Failed to upgrade packages from dnf."
    fi
    info "Installing dependencies."
    dnf -y install curl git grep newt rsync sed > /dev/null 2>&1 || fatal "Failed to install dependencies from dnf."
    info "Removing unused packages."
    dnf -y autoremove > /dev/null 2>&1 || fatal "Failed to remove unused packages from dnf."
    info "Cleaning up package cache."
    dnf -y clean all > /dev/null 2>&1 || fatal "Failed to cleanup cache from dnf."
}
