#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_yum_upgrade() {
    if [[ ${CI:-} != true ]]; then
        notice "Upgrading packages. Please be patient, this can take a while."
        local REDIRECT="> /dev/null 2>&1"
        if [[ -n ${VERBOSE:-} ]] || run_script 'question_prompt' "${PROMPT:-CLI}" N "Would you like to display the command output?"; then
            REDIRECT=""
        fi
        eval yum -y upgrade "${REDIRECT}" || fatal "Failed to upgrade packages from yum.\nFailing command: ${F[C]}yum -y upgrade \"${REDIRECT}\""
    fi
}

test_pm_yum_upgrade() {
    # run_script 'pm_yum_upgrade'
    warn "CI does not test pm_yum_upgrade."
}
