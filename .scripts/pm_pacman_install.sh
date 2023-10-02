#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_pacman_install() {
    notice "Installing dependencies. Please be patient, this can take a while."
    local REDIRECT="> /dev/null 2>&1"
    if [[ -n ${VERBOSE-} ]] || run_script 'question_prompt' "${PROMPT:-CLI}" N "Would you like to display the command output?"; then
        REDIRECT=""
    fi
    eval "sudo pacman -Sy --noconfirm curl git grep libnewt sed ${REDIRECT}" || fatal "Failed to install dependencies using pacman.\nFailing command: ${F[C]}sudo pacman -Sy --noconfirm curl git grep libnewt sed"
}

test_pm_pacman_install() {
    # run_script 'pm_pacman_repos'
    # run_script 'pm_pacman_install'
    warn "CI does not test pm_pacman_install."
}
