#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_apk_install_docker() {
    notice "Installing docker. Please be patient, this can take a while."
    local REDIRECT="> /dev/null 2>&1"
    if [[ -n ${VERBOSE-} ]] || run_script 'question_prompt' "${PROMPT:-CLI}" N "Would you like to display the command output?"; then
        REDIRECT=""
    fi
    eval "sudo apk add docker docker-cli-compose ${REDIRECT}" || fatal "Failed to install docker and docker-compose using pacman.\nFailing command: ${F[C]}sudo apk add docker docker-cli-compose"

}

test_pm_apk_install_docker() {
    # run_script 'pm_apk_repos'
    # run_script 'pm_apk_install_docker'
    warn "CI does not test pm_apk_install_docker."
}
