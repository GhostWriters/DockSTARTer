#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_yum_install() {
    notice "Installing dependencies. Please be patient, this can take a while."
    local REDIRECT="> /dev/null 2>&1"
    if [[ -n ${VERBOSE-} ]] || run_script 'question_prompt' "${PROMPT:-CLI}" N "Would you like to display the command output?"; then
        REDIRECT=""
    fi
    eval "sudo yum -y install curl git grep newt sed ${REDIRECT}" || fatal "Failed to install dependencies from yum.\nFailing command: ${F[C]}sudo yum -y install curl git grep newt sed"
}

test_pm_yum_install() {
    # run_script 'pm_yum_repos'
    # run_script 'pm_yum_install'
    warn "CI does not test pm_yum_install."
}
