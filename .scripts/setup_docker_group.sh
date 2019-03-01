#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

setup_docker_group() {
    # https://docs.docker.com/install/linux/linux-postinstall/
    info "Creating docker group."
    groupadd -f docker > /dev/null 2>&1 || fatal "Failed to create docker group."
    if [[ ${CI:-} == true ]] && [[ ${TRAVIS:-} == true ]]; then
        info "Skipping usermod on Travis."
    else
        info "Adding ${DETECTED_UNAME} to docker group."
        usermod -aG docker "${DETECTED_UNAME}" > /dev/null 2>&1 || fatal "Failed to add ${DETECTED_UNAME} to docker group."
    fi
}

test_setup_docker_group() {
    run_script 'setup_docker_group'
}
