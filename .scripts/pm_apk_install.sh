#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_apk_install() {
    notice "Installing dependencies. Please be patient, this can take a while."
    local REDIRECT="> /dev/null 2>&1"
    if [[ -n ${VERBOSE-} ]] || run_script 'question_prompt' "${PROMPT:-CLI}" N "Would you like to display the command output?"; then
        REDIRECT=""
    fi
    eval "sudo apk add coreutils curl git grep newt openrc sed ${REDIRECT}" || fatal "Failed to install dependencies from apk.\nFailing command: ${F[C]}sudo apk add coreutils curl git grep newt sed"
}

test_pm_apk_install() {
    # run_script 'pm_apk_repos'
    # run_script 'pm_apk_install'
    warn "CI does not test pm_apk_install."
}
