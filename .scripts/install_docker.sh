#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

install_docker() {
    local MINIMUM_DOCKER="17.09.0"
    run_script 'remove_snap_docker'
    local INSTALLED_DOCKER
    INSTALLED_DOCKER=$( (docker --version 2> /dev/null || echo "0") | sed -E 's/.* version ([^,]*)(, build .*)?/\1/')
    # Find minimum compatible version at https://docs.docker.com/engine/release-notes/
    if vergt "${MINIMUM_DOCKER}" "${INSTALLED_DOCKER}"; then
        local AVAILABLE_DOCKER
        AVAILABLE_DOCKER=$( (curl -H "${GH_HEADER:-}" -fsL "https://api.github.com/repos/docker/docker-ce/releases/latest" | grep -Po '"tag_name": "[Vv]?\K.*?(?=")') || echo "0")
        if [[ ${AVAILABLE_DOCKER} == "0" ]]; then
            if [[ ${INSTALLED_DOCKER} == "0" ]]; then
                fatal "The latest available version of docker could not be confirmed. This is usually caused by exhausting the rate limit on GitHub's API. Please check https://api.github.com/rate_limit"
            else
                warn "Failed to check latest available docker version. This can be ignored for now."
                return
            fi
        fi
        if vergt "${AVAILABLE_DOCKER}" "${INSTALLED_DOCKER}"; then
            run_script 'package_manager_run' remove_docker
            # https://github.com/docker/docker-install
            notice "Installing latest docker. Please be patient, this can take a while."
            local GET_DOCKER
            GET_DOCKER=$(mktemp) || fatal "Failed to create temporary docker install script."
            info "Downloading docker install script."
            curl -fsSL get.docker.com -o "${GET_DOCKER}" > /dev/null 2>&1 || fatal "Failed to get docker install script."
            info "Running docker install script."
            local REDIRECT="> /dev/null 2>&1"
            if [[ -n ${VERBOSE:-} ]] || run_script 'question_prompt' "${PROMPT:-}" N "Would you like to display the command output?"; then
                REDIRECT=""
            fi
            eval sh "${GET_DOCKER}" "${REDIRECT}" || fatal "Failed to install docker."
            rm -f "${GET_DOCKER}" || warn "Failed to remove temporary docker install script."
            local UPDATED_DOCKER
            UPDATED_DOCKER=$( (docker --version 2> /dev/null || echo "0") | sed -E 's/.* version ([^,]*)(, build .*)?/\1/')
            if vergt "${AVAILABLE_DOCKER}" "${UPDATED_DOCKER}"; then
                #TODO: Better detection of most recently available version is required before this can be used.
                echo # placeholder
                #fatal "Failed to install the latest docker."
            fi
        fi
    fi
}

test_install_docker() {
    run_script 'install_docker'
    docker --version || fatal "Failed to determine docker version."
}
