#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

setup_docker_group() {
    # https://docs.docker.com/install/linux/linux-postinstall/
    info "Creating docker group."
    sudo groupadd -f docker > /dev/null 2>&1 || fatal "Failed to create docker group.\nFailing command: ${C["FailingCommand"]}sudo groupadd -f docker"
    if [[ ${CI-} == true ]]; then
        notice "Skipping usermod in CI."
    else
        info "Adding '${C["User"]}${DETECTED_UNAME}${NC}' to docker group."
        sudo usermod -aG docker "${DETECTED_UNAME}" > /dev/null 2>&1 || fatal "Failed to add '${C["User"]}${DETECTED_UNAME}${NC}' to docker group.\nFailing command: ${C["FailingCommand"]}sudo usermod -aG docker \"${DETECTED_UNAME}\""
    fi
}

test_setup_docker_group() {
    run_script 'setup_docker_group'
}
