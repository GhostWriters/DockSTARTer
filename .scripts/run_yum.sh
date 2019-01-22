#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

run_yum() {
    # https://docs.docker.com/install/linux/docker-ce/centos/
    info "Removing old Docker packages."
    run_cmd yum -y remove docker \
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
        run_cmd yum -y upgrade || fatal "Failed to upgrade packages from yum."
    fi
    info "Installing dependencies."
    run_cmd yum -y install curl git grep newt rsync sed || fatal "Failed to install dependencies from yum."
    info "Removing unused packages."
    run_cmd yum -y autoremove || fatal "Failed to remove unused packages from yum."
    info "Cleaning up package cache."
    run_cmd yum -y clean all || fatal "Failed to cleanup cache from yum."
}
