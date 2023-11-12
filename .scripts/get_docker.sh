#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

get_docker() {
    # https://github.com/docker/docker-install
    notice "Installing docker. Please be patient, this can take a while."
    local MKTEMP_GET_DOCKER
    MKTEMP_GET_DOCKER=$(mktemp) || fatal "Failed to create temporary docker install script.\nFailing command: ${F[C]}mktemp"
    info "Downloading docker install script."
    curl -fsSL https://get.docker.com -o "${MKTEMP_GET_DOCKER}" > /dev/null 2>&1 || fatal "Failed to get docker install script.\nFailing command: ${F[C]}curl -fsSL https://get.docker.com -o \"${MKTEMP_GET_DOCKER}\""
    info "Running docker install script."
    local REDIRECT="> /dev/null 2>&1"
    if [[ -n ${VERBOSE-} ]] || run_script 'question_prompt' "${PROMPT:-CLI}" N "Would you like to display the command output?"; then
        REDIRECT=""
    fi
    eval "sh ${MKTEMP_GET_DOCKER} ${REDIRECT}" || fatal "Failed to install docker.\nFailing command: ${F[C]}sh ${MKTEMP_GET_DOCKER}"
    rm -f "${MKTEMP_GET_DOCKER}" || warn "Failed to remove temporary docker install script.\nFailing command: ${F[C]}rm -f \"${MKTEMP_GET_DOCKER}\""
}

test_get_docker() {
    run_script 'remove_snap_docker'
    run_script 'get_docker'
    docker --version || fatal "Failed to determine docker version.\nFailing command: ${F[C]}docker --version"
    docker compose version || fatal "Failed to determine docker compose version.\nFailing command: ${F[C]}docker compose version"
}
