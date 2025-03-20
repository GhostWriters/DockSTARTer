#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_apt_install() {
    local Title="Install Dependencies"
    notice "Installing dependencies. Please be patient, this can take a while."
    local COMMAND=""
    local REDIRECT="> /dev/null 2>&1"
    if [[ -n ${VERBOSE-} ]] || run_script 'question_prompt' "${PROMPT:-CLI}" N "Would you like to display the command output?" "${Title}"; then
        if [[ ${PROMPT:-CLI} == CLI ]]; then
            REDIRECT=""
        else
            REDIRECT="2>&1 | dialog --clear --title \"${Title}\" --programbox \"\${COMMAND}\" -1 -1"
        fi
    fi
    COMMAND="sudo apt-get -y install curl git grep sed whiptail dialog"
    eval "${COMMAND} ${REDIRECT}" || fatal "Failed to install dependencies from apt.\nFailing command: ${F[C]}${COMMAND}"
    if [[ ${PROMPT:-CLI} != CLI ]]; then
        clear
    fi
}

test_pm_apt_install() {
    run_script 'pm_apt_repos'
    run_script 'pm_apt_install'
}
