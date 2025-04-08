#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

get_docker() {
    Title="Install Docker"
    notice "Installing docker. Please be patient, this can take a while."
    local COMMAND=""
    local REDIRECT="> /dev/null 2>&1"
    if run_script 'question_prompt' N "Would you like to display the command output?" "${Title}" "${VERBOSE:+Y}"; then
        if [[ ${PROMPT:-CLI} == GUI && -t 1 ]]; then
            #shellcheck disable=SC2016 # (info): Expressions don't expand in single quotes, use double quotes for that.
            REDIRECT='|& dialog_pipe "${Title}" "${COMMAND}"'
        else
            REDIRECT=""
        fi
    fi
    COMMAND="command_get_docker"
    eval "${COMMAND} ${REDIRECT}"
}

command_get_docker() {
    # https://github.com/docker/docker-install
    local MKTEMP_GET_DOCKER
    MKTEMP_GET_DOCKER=$(mktemp) || fatal "Failed to create temporary docker install script.\nFailing command: ${F[C]}mktemp"
    info "Downloading docker install script."
    COMMAND="curl -fsSL https://get.docker.com -o \"${MKTEMP_GET_DOCKER}\""
    eval "${COMMAND}" || fatal "Failed to get docker install script.\nFailing command: ${F[C]}${COMMAND}"
    info "Running docker install script."
    COMMAND="sh ${MKTEMP_GET_DOCKER}"
    eval "${COMMAND}" || fatal "Failed to install docker.\nFailing command: ${F[C]}${COMMAND}"
    COMMAND="rm -f \"${MKTEMP_GET_DOCKER}\""
    eval "${COMMAND}" || warn "Failed to remove temporary docker install script.\nFailing command: ${F[C]}${COMMAND}"
}

test_get_docker() {
    run_script 'remove_snap_docker'
    run_script 'get_docker'
    docker --version || fatal "Failed to determine docker version.\nFailing command: ${F[C]}docker --version"
    docker compose version || fatal "Failed to determine docker compose version.\nFailing command: ${F[C]}docker compose version"
}
