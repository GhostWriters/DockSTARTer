#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_yum_remove_docker() {
    # https://docs.docker.com/install/linux/docker-ce/centos/
    info "Removing conflicting Docker packages."
    yum -y remove docker \
        docker-client \
        docker-client-latest \
        docker-common \
        docker-compose \
        docker-engine \
        docker-latest \
        docker-latest-logrotate \
        docker-logrotate > /dev/null 2>&1 || true
}

test_pm_yum_remove_docker() {
    # run_script 'pm_yum_remove_docker'
    warn "CI does not test pm_yum_remove_docker."
}
