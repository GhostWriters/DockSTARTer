#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

pm_apt_remove_docker() {
    # https://docs.docker.com/install/linux/docker-ce/debian/
    # https://docs.docker.com/install/linux/docker-ce/ubuntu/
    info "Removing conflicting Docker packages."
    apt-get -y remove containerd \
        docker \
        docker-compose \
        docker-engine \
        docker.io \
        runc > /dev/null 2>&1 || true
}

test_pm_apt_remove_docker() {
    run_script 'pm_apt_remove_docker'
}
