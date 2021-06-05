#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_pacman_install_docker() {
    notice "Installing docker. Please be patient, this can take a while."
    local REDIRECT="> /dev/null 2>&1"
    if [[ -n ${VERBOSE:-} ]] || run_script 'question_prompt' "${PROMPT:-CLI}" N "Would you like to display the command output?"; then
        REDIRECT=""
    fi
    eval pacman -Sy --noconfirm docker "${REDIRECT}" || fatal "Failed to install docker using pacman.\nFailing command: ${F[C]}pacman -Sy --noconfirm docker"
}

test_pm_pacman_install_docker() {
    # run_script 'pm_pacman_install_docker'
    warn "CI does not test pm_pacman_install_docker."
}
