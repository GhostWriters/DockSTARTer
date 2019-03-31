#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

run_dnf() {
    # https://docs.docker.com/install/linux/docker-ce/fedora/
    info "Removing conflicting packages."
    dnf -y remove docker \
        docker-client \
        docker-client-latest \
        docker-common \
        docker-compose \
        docker-latest \
        docker-latest-logrotate \
        docker-logrotate \
        docker-selinux \
        docker-engine-selinux \
        docker-engine \
        python-cryptography \
        python3-cryptography > /dev/null 2>&1 || true
    if [[ ${CI:-} != true ]] && [[ ${TRAVIS:-} != true ]]; then
        info "Upgrading packages. Please be patient, this can take a while."
        dnf -y upgrade --refresh > /dev/null 2>&1 || fatal "Failed to upgrade packages from dnf."
    fi
    info "Installing dependencies."
    dnf -y install curl git grep newt python3 python3-pip rsync sed > /dev/null 2>&1 || fatal "Failed to install dependencies from dnf."
    # https://cryptography.io/en/latest/installation/#building-cryptography-on-linux
    dnf -y install redhat-rpm-config gcc libffi-devel python3-devel openssl-devel > /dev/null 2>&1 || fatal "Failed to install python cryptography dependencies from dnf."
    info "Removing unused packages."
    dnf -y autoremove > /dev/null 2>&1 || fatal "Failed to remove unused packages from dnf."
    info "Cleaning up package cache."
    dnf -y clean all > /dev/null 2>&1 || fatal "Failed to cleanup cache from dnf."
}

test_run_dnf() {
    # run_script 'run_dnf'
    warning "Travis does not test run_dnf."
}
