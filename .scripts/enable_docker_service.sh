#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

enable_docker_service() {
    DOCKER_SERVICE_ENABLE=""
    DOCKER_SERVICE_START=""
    if [[ -n "$(command -v systemctl)" ]]; then
        info "Systemd detected."
        DOCKER_SERVICE_ENABLE="systemctl enable docker"
        DOCKER_SERVICE_START="systemctl start docker"
    elif [[ -n "$(command -v rc-update)" ]]; then
        info "OpenRC detected."
        DOCKER_SERVICE_ENABLE="rc-update add docker boot"
        DOCKER_SERVICE_START="service docker start"
    fi
    if [[ -n ${DOCKER_SERVICE_ENABLE} ]]; then
        info "Enabling docker service."
        eval "sudo ${DOCKER_SERVICE_ENABLE}" > /dev/null 2>&1 || fatal "Failed to enable docker service.\nFailing command: ${F[C]}${DOCKER_SERVICE_ENABLE}"
        info "Starting docker service."
        eval "sudo ${DOCKER_SERVICE_START}" > /dev/null 2>&1 || fatal "Failed to start docker service.\nFailing command: ${F[C]}${DOCKER_SERVICE_START}"
    fi
}

test_enable_docker_service() {
    run_script 'require_docker'
    run_script 'enable_docker_service'
}
