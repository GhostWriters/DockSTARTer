#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_apk_install() {
    Title="Install Dependencies"
    notice "Installing dependencies. Please be patient, this can take a while."
    local REDIRECT="> /dev/null 2>&1"
    if run_script 'question_prompt' N "Would you like to display the command output?" "${Title}" "${VERBOSE:+Y}"; then
        REDIRECT=""
    fi
    eval "sudo apk add coreutils curl dialog git grep openrc sed ${REDIRECT}" || fatal "Failed to install dependencies from apk.\nFailing command: ${F[C]}sudo apk add coreutils curl dialog git grep sed"
}

test_pm_apk_install() {
    # run_script 'pm_apk_repos'
    # run_script 'pm_apk_install'
    warn "CI does not test pm_apk_install."
}
