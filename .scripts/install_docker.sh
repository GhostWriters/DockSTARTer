#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

install_docker() {
    # https://github.com/docker/docker-install
    local AVAILABLE_DOCKER
    AVAILABLE_DOCKER=$(curl -H "${GH_HEADER:-}" -s "https://api.github.com/repos/docker/docker-ce/releases/latest" | grep -Po '"tag_name": "[Vv]?\K.*?(?=")') || fatal "Failed to check latest available docker version."
    local INSTALLED_DOCKER
    INSTALLED_DOCKER=$( (docker --version 2> /dev/null || true) | sed -E 's/.* version ([^,]*)(, build .*)?/\1/')
    local FORCE
    FORCE=${1:-}
    if [[ ${AVAILABLE_DOCKER} != "${INSTALLED_DOCKER}" ]] || [[ -n ${FORCE} ]]; then
        info "Installing latest docker. Please be patient, this will take a while."
        curl -fsSL get.docker.com | sh > /dev/null 2>&1 || fatal "Failed to install docker."
        local UPDATED_DOCKER
        UPDATED_DOCKER=$( (docker --version 2> /dev/null || true) | sed -E 's/.* version ([^,]*)(, build .*)?/\1/')
        if [[ ${AVAILABLE_DOCKER} != "${UPDATED_DOCKER}" ]]; then
            #TODO: Better detection of most recently available version is required before this can be used.
            echo # placeholder
            #fatal "Failed to install the latest docker."
        fi
    fi
}
