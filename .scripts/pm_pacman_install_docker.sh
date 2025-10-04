#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_pacman_install_docker() {
    #shellcheck disable=SC2034 #(warning): Title appears unused. Verify use (or export if used externally).
    local Title="Install Docker"
    notice "Installing docker. Please be patient, this can take a while."
    local COMMAND='sudo pacman -Sy --noconfirm docker docker-compose'
    local REDIRECT='> /dev/null 2>&1 '
    if [[ -n ${VERBOSE-} ]]; then
        #shellcheck disable=SC2016 # (info): Expressions don't expand in single quotes, use double quotes for that.
        REDIRECT='run_command_dialog "${Title}" "${COMMAND}" "" '
    fi
    eval "${REDIRECT}${COMMAND}" || fatal "Failed to install docker and docker-compose using pacman.\nFailing command: ${C["FailingCommand"]}${COMMAND}"
}

test_pm_pacman_install_docker() {
    # run_script 'pm_pacman_repos'
    # run_script 'pm_pacman_install_docker'
    warn "CI does not test pm_pacman_install_docker."
}
