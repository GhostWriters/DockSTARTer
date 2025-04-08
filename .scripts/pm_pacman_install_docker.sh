#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_pacman_install_docker() {
    local Title="Install Docker"
    notice "Installing docker. Please be patient, this can take a while."
    local REDIRECT="> /dev/null 2>&1"
    if run_script 'question_prompt' N "Would you like to display the command output?" "${Title}" "${VERBOSE:+Y}"; then
        REDIRECT=""
    fi
    eval "sudo pacman -Sy --noconfirm docker docker-compose ${REDIRECT}" || fatal "Failed to install docker and docker-compose using pacman.\nFailing command: ${F[C]}sudo pacman -Sy --noconfirm docker docker-compose"
}

test_pm_pacman_install_docker() {
    # run_script 'pm_pacman_repos'
    # run_script 'pm_pacman_install_docker'
    warn "CI does not test pm_pacman_install_docker."
}
