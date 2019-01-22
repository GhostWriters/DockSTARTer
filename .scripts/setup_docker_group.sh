#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

setup_docker_group() {
    # https://docs.docker.com/install/linux/linux-postinstall/
    info "Creating docker group."
    run_cmd groupadd -f docker || fatal "Failed to create docker group."
    if [[ ${CI:-} == true ]] && [[ ${TRAVIS:-} == true ]]; then
        info "Skipping usermod on Travis."
    else
        info "Adding ${DETECTED_UNAME} to docker group."
        run_cmd usermod -aG docker "${DETECTED_UNAME}" || fatal "Failed to add ${DETECTED_UNAME} to docker group."
    fi
}
