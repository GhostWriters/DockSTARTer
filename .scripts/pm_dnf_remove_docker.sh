#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

pm_dnf_remove_docker() {
    # https://docs.docker.com/install/linux/docker-ce/fedora/
    info "Removing conflicting Docker packages."
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
        docker-engine > /dev/null 2>&1 || true
}

test_pm_dnf_remove_docker() {
    # run_script 'pm_dnf_remove_docker'
    warning "Travis does not test pm_dnf_remove_docker."
}
