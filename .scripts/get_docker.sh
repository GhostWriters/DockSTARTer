#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

get_docker() {
    Title="Install Docker"
    notice "Installing docker. Please be patient, this can take a while."
    if run_script 'question_prompt' Y "Would you like to display the command output?" "${Title}" "${VERBOSE:+Y}"; then
        if use_dialog_box; then
            command_get_docker |& dialog_pipe "${Title}" "Installing docker. Please be patient, this can take a while."
        else
            command_get_docker
        fi
    else
        command_get_docker > /dev/null 2>&1
    fi
}

command_get_docker() {
    # https://github.com/docker/docker-install
    local MKTEMP_GET_DOCKER
    local COMMAND
    #shellcheck disable=SC2034 # (warning): MKTEMP_GET_DOCKER appears unused. Verify use (or export if used externally).
    MKTEMP_GET_DOCKER=$(mktemp -t "${APPLICATION_NAME}.${FUNCNAME[0]}.MKTEMP_GET_DOCKER.XXXXXXXXXX") ||
        fatal "Failed to create temporary docker install script.\nFailing command: ${C["FailingCommand"]}mktemp -t \"${APPLICATION_NAME}.${FUNCNAME[0]}.MKTEMP_GET_DOCKER.XXXXXXXXXX\""
    info "Downloading docker install script."
    #shellcheck disable=SC2016 # (info): Expressions don't expand in single quotes, use double quotes for that.
    COMMAND="curl -fsSL https://get.docker.com -o '${MKTEMP_GET_DOCKER}'"
    info "Running: ${C["RunningCommand"]}${COMMAND}${NC}"
    eval "${COMMAND}" ||
        fatal "Failed to get docker install script.\nFailing command: ${C["FailingCommand"]}${COMMAND}"
    info "Running docker install script."
    #shellcheck disable=SC2016 # (info): Expressions don't expand in single quotes, use double quotes for that.
    COMMAND="sh '${MKTEMP_GET_DOCKER}'"
    info "Running: ${C["RunningCommand"]}${COMMAND}${NC}"
    eval "${COMMAND}" ||
        fatal "Failed to install docker.\nFailing command: ${C["FailingCommand"]}${COMMAND}"
    #shellcheck disable=SC2016 # (info): Expressions don't expand in single quotes, use double quotes for that.
    COMMAND='rm -f "${MKTEMP_GET_DOCKER}"'
    eval "${COMMAND}" ||
        warn "Failed to remove temporary docker install script.\nFailing command: ${C["FailingCommand"]}${COMMAND}"
}

test_get_docker() {
    run_script 'remove_snap_docker'
    run_script 'get_docker'
    docker --version || fatal "Failed to determine docker version.\nFailing command: ${C["FailingCommand"]}docker --version"
    docker compose version || fatal "Failed to determine docker compose version.\nFailing command: ${C["FailingCommand"]}docker compose version"
}
