#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

run_dnf() {
    if [[ ${CI:-} != true ]] && [[ ${TRAVIS:-} != true ]]; then
        info "Upgrading packages."
        dnf -y upgrade --refresh > /dev/null 2>&1
    fi
    info "Installing dependencies."
    dnf -y install curl git grep sed whiptail > /dev/null 2>&1
    info "Removing unused packages."
    dnf -y autoremove > /dev/null 2>&1
    info "Cleaning up package cache."
    dnf -y clean all > /dev/null 2>&1
}
