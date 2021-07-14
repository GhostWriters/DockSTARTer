#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_apt_install_docker() {
    notice "Installing docker. Please be patient, this can take a while."
    local REDIRECT="> /dev/null 2>&1"
    if [[ -n ${VERBOSE:-} ]] || run_script 'question_prompt' "${PROMPT:-CLI}" N "Would you like to display the command output?"; then
        REDIRECT=""
    fi
    eval apt-get -y install containerd docker.io runc "${REDIRECT}" || fatal "Failed to install docker from apt.\nFailing command: ${F[C]}apt-get -y install containerd docker.io runc"
}

test_pm_apt_install_docker() {
    run_script 'pm_apt_repos'
    run_script 'pm_apt_install_docker'
}
