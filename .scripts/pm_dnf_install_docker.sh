#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_dnf_install_docker() {
    notice "Installing docker. Please be patient, this can take a while."
    local REDIRECT="> /dev/null 2>&1"
    if [[ -n ${VERBOSE:-} ]] || run_script 'question_prompt' "${PROMPT:-CLI}" N "Would you like to display the command output?"; then
        REDIRECT=""
    fi
    eval dnf -y install docker "${REDIRECT}" || fatal "Failed to install docker from dnf.\nFailing command: ${F[C]}dnf -y install docker"
}

test_pm_dnf_install_docker() {
    # run_script 'pm_dnf_install_docker'
    warn "CI does not test pm_dnf_install_docker."
}
