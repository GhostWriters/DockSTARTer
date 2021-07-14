#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_yum_install_docker() {
    notice "Installing docker. Please be patient, this can take a while."
    local REDIRECT="> /dev/null 2>&1"
    if [[ -n ${VERBOSE:-} ]] || run_script 'question_prompt' "${PROMPT:-CLI}" N "Would you like to display the command output?"; then
        REDIRECT=""
    fi
    eval yum -y install docker "${REDIRECT}" || fatal "Failed to install docker from yum.\nFailing command: ${F[C]}yum -y install docker"
}

test_pm_yum_install_docker() {
    # run_script 'pm_yum_install_docker'
    warn "CI does not test pm_yum_install_docker."
}
