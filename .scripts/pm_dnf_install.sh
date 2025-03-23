#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_dnf_install() {
    local Title="Install Dependencies"
    notice "Installing dependencies. Please be patient, this can take a while."
    local REDIRECT="> /dev/null 2>&1"
    if [[ -n ${VERBOSE-} ]] || run_script 'question_prompt' N "Would you like to display the command output?" "${Title}"; then
        REDIRECT=""
    fi
    eval "sudo dnf -y install ansifilter curl dialog git grep newt sed ${REDIRECT}" || fatal "Failed to install dependencies from dnf.\nFailing command: ${F[C]}sudo dnf -y install curl git grep newt sed dialog"
}

test_pm_dnf_install() {
    # run_script 'pm_dnf_repos'
    # run_script 'pm_dnf_install'
    warn "CI does not test pm_dnf_install."
}
