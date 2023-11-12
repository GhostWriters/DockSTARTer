#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_apt_install() {
    notice "Installing dependencies. Please be patient, this can take a while."
    local REDIRECT="> /dev/null 2>&1"
    if [[ -n ${VERBOSE-} ]] || run_script 'question_prompt' "${PROMPT:-CLI}" N "Would you like to display the command output?"; then
        REDIRECT=""
    fi
    eval "sudo apt-get -y install curl git grep sed whiptail ${REDIRECT}" || fatal "Failed to install dependencies from apt.\nFailing command: ${F[C]}sudo apt-get -y install curl git grep sed whiptail"
}

test_pm_apt_install() {
    run_script 'pm_apt_repos'
    run_script 'pm_apt_install'
}
