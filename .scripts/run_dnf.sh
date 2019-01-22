#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

run_dnf() {
    # https://docs.docker.com/install/linux/docker-ce/fedora/
    info "Removing old Docker packages."
    run_cmd dnf -y remove docker \
        docker-client \
        docker-client-latest \
        docker-common \
        docker-latest \
        docker-latest-logrotate \
        docker-logrotate \
        docker-selinux \
        docker-engine-selinux \
        docker-engine || true
    if [[ ${CI:-} != true ]] && [[ ${TRAVIS:-} != true ]]; then
        info "Upgrading packages."
        run_cmd dnf -y upgrade --refresh || fatal "Failed to upgrade packages from dnf."
    fi
    info "Installing dependencies."
    run_cmd dnf -y install curl git grep newt rsync sed || fatal "Failed to install dependencies from dnf."
    info "Removing unused packages."
    run_cmd dnf -y autoremove || fatal "Failed to remove unused packages from dnf."
    info "Cleaning up package cache."
    run_cmd dnf -y clean all || fatal "Failed to cleanup cache from dnf."
}
