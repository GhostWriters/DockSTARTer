#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

run_apt() {
    info "Updating repositories."
    apt-get update > /dev/null 2>&1
    if [[ ${CI:-} != true ]] && [[ ${TRAVIS:-} != true ]]; then
        info "Upgrading packages."
        apt-get -y dist-upgrade > /dev/null 2>&1
    fi
    info "Installing dependencies."
    apt-get -qq install curl git grep sed apt-transport-https whiptail > /dev/null 2>&1
    info "Removing unused packages."
    apt-get -y autoremove > /dev/null 2>&1
    info "Cleaning up unused packages."
    apt-get -y autoclean > /dev/null 2>&1
}
