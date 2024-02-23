#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_dnf_install_docker() {
    # https://docs.docker.com/install/linux/docker-ce/fedora/
    info "Removing conflicting Docker packages."
    sudo dnf -y remove docker \
        docker-client \
        docker-client-latest \
        docker-common \
        docker-compose \
        docker-engine \
        docker-engine-selinux \
        docker-latest \
        docker-latest-logrotate \
        docker-logrotate \
        docker-selinux > /dev/null 2>&1 || true
    run_script 'remove_snap_docker'
    run_script 'get_docker'
}

test_pm_dnf_install_docker() {
    # run_script 'pm_dnf_repos'
    # run_script 'pm_dnf_install_docker'
    warn "CI does not test pm_dnf_install_docker."
}
