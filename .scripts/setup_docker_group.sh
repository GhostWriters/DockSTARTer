#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

setup_docker_group() {
    # https://docs.docker.com/install/linux/linux-postinstall/
    info "Creating docker group."
    add_group docker &> /dev/null ||
        fatal "Failed to create docker group."
    if [[ ${CI-} == true ]]; then
        notice "Skipping usermod in CI."
    else
        info "Adding '${C["User"]}${DETECTED_UNAME}${NC}' to docker group."
        add_user_to_group "${DETECTED_UNAME}" docker &> /dev/null ||
            fatal "Failed to add '${C["User"]}${DETECTED_UNAME}${NC}' to docker group."
    fi
}

test_setup_docker_group() {
    run_script 'setup_docker_group'
}
