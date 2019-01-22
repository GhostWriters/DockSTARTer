#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

run_apt() {
    # https://docs.docker.com/install/linux/docker-ce/debian/
    # https://docs.docker.com/install/linux/docker-ce/ubuntu/
    info "Removing old Docker packages."
    run_cmd apt-get -y remove docker docker-engine docker.io || true
    info "Updating repositories."
    run_cmd apt-get -y update || fatal "Failed to get updates from apt."
    if [[ ${CI:-} != true ]] && [[ ${TRAVIS:-} != true ]]; then
        info "Upgrading packages."
        run_cmd apt-get -y dist-upgrade || fatal "Failed to upgrade packages from apt."
    fi
    info "Installing dependencies."
    run_cmd apt-get -y install apt-transport-https curl git grep rsync sed whiptail || fatal "Failed to install dependencies from apt."
    info "Removing unused packages."
    run_cmd apt-get -y autoremove || fatal "Failed to remove unused packages from apt."
    info "Cleaning up package cache."
    run_cmd apt-get -y autoclean || fatal "Failed to cleanup cache from apt."
}
