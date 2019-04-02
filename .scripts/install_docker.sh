#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

install_docker() {
    # https://github.com/docker/docker-install
    local AVAILABLE_DOCKER
    AVAILABLE_DOCKER=$( (curl -H "${GH_HEADER:-}" -s "https://api.github.com/repos/docker/docker-ce/releases/latest" || echo "0") | grep -Po '"tag_name": "[Vv]?\K.*?(?=")')
    local INSTALLED_DOCKER
    INSTALLED_DOCKER=$( (docker --version 2> /dev/null || echo "0") | sed -E 's/.* version ([^,]*)(, build .*)?/\1/')
    local FORCE
    FORCE=${1:-}
    if [[ ${AVAILABLE_DOCKER} == "0" ]]; then
        if [[ ${INSTALLED_DOCKER} == "0" ]] || [[ -n ${FORCE} ]]; then
            warning "Failed to check latest available docker version."
            fatal "docker is required but cannot be installed. Please check https://api.github.com/rate_limit"
        else
            warning "Failed to check latest available docker version."
            return
        fi
    fi
    local FORCE
    FORCE=${1:-}
    if vergt "${AVAILABLE_DOCKER}" "${INSTALLED_DOCKER}" || [[ -n ${FORCE} ]]; then
        if [[ -n "$(command -v snap)" ]]; then
            info "Removing snap Docker package."
            snap remove docker > /dev/null 2>&1 || true
        fi
        info "Installing latest docker. Please be patient, this can take a while."
        curl -fsSL get.docker.com | sh > /dev/null 2>&1 || fatal "Failed to install docker."
        local UPDATED_DOCKER
        UPDATED_DOCKER=$( (docker --version 2> /dev/null || echo "0") | sed -E 's/.* version ([^,]*)(, build .*)?/\1/')
        if vergt "${AVAILABLE_DOCKER}" "${UPDATED_DOCKER}"; then
            #TODO: Better detection of most recently available version is required before this can be used.
            echo # placeholder
            #fatal "Failed to install the latest docker."
        fi
    fi
}

test_install_docker() {
    run_script 'install_docker'
    docker --version || fatal "Failed to determine docker version."
}
