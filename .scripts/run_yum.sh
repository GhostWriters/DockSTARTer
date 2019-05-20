#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

run_yum() {
    # https://docs.docker.com/install/linux/docker-ce/centos/
    info "Removing conflicting packages."
    yum -y remove docker \
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
        python3-cryptography \
        python36 \
        python36-pip > /dev/null 2>&1 || true
    info "Installing EPEL and IUS repositories."
    local GET_IUS
    GET_IUS="$(mktemp)"
    curl -fsSL setup.ius.io -o "${GET_IUS}" > /dev/null 2>&1 || fatal "Failed to get IUS install script."
    bash "${GET_IUS}" > /dev/null 2>&1 || warning "Failed to install IUS."
    rm -f "${GET_IUS}" || warning "Temporary setup.ius.io file could not be removed."
    if [[ ${CI:-} != true ]] && [[ ${TRAVIS:-} != true ]]; then
        info "Upgrading packages. Please be patient, this can take a while."
        yum -y upgrade > /dev/null 2>&1 || fatal "Failed to upgrade packages from yum."
    fi
    info "Installing dependencies."
    yum -y install curl git grep newt python36u python36u-pip rsync sed > /dev/null 2>&1 || fatal "Failed to install dependencies from yum."
    # https://cryptography.io/en/latest/installation/#building-cryptography-on-linux
    yum -y install redhat-rpm-config gcc libffi-devel python36u-devel openssl-devel > /dev/null 2>&1 || fatal "Failed to install python cryptography dependencies from yum."
    info "Removing unused packages."
    yum -y autoremove > /dev/null 2>&1 || fatal "Failed to remove unused packages from yum."
    info "Cleaning up package cache."
    yum -y clean all > /dev/null 2>&1 || fatal "Failed to cleanup cache from yum."
}

test_run_yum() {
    # run_script 'run_yum'
    warning "Travis does not test run_yum."
}
