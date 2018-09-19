#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

install_docker() {
    # https://github.com/docker/docker-install
    local AVAILABLE_DOCKER
    AVAILABLE_DOCKER=$(curl -H "${GH_HEADER:-}" -s "https://api.github.com/repos/docker/docker-ce/releases/latest" | grep -Po '"tag_name": "[Vv]?\K.*?(?=")')
    local INSTALLED_DOCKER
    INSTALLED_DOCKER=$( (docker --version 2> /dev/null || true) | sed -E 's/.* version ([^,]*)(, build .*)?/\1/')
    local FORCE
    FORCE=${1:-}
    if [[ "${AVAILABLE_DOCKER}" != "${INSTALLED_DOCKER}" ]] || [[ -n ${FORCE} ]]; then
        info "Installing latest docker. Please be patient, this will take a while."
        curl -fsSL get.docker.com | sh > /dev/null 2>&1
    fi
}
