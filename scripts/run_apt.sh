#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

run_apt() {
    info "Updating repositories."
    apt-get -y update > /dev/null 2>&1 || fatal "Failed to get updates from apt."
    if [[ ${CI:-} != true ]] && [[ ${TRAVIS:-} != true ]]; then
        info "Upgrading packages."
        apt-get -y dist-upgrade > /dev/null 2>&1 || fatal "Failed to upgrade packages from apt."
    fi
    info "Installing dependencies."
    apt-get -y install apt-transport-https curl git grep rsync sed whiptail > /dev/null 2>&1 || fatal "Failed to install dependencies from apt."
    info "Removing unused packages."
    apt-get -y autoremove > /dev/null 2>&1 || fatal "Failed to remove unused packages from apt."
    info "Cleaning up package cache."
    apt-get -y autoclean > /dev/null 2>&1 || fatal "Failed to cleanup cache from apt."
}
