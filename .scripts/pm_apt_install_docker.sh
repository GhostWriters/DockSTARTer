#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_apt_install_docker() {
    # https://docs.docker.com/install/linux/docker-ce/debian/
    # https://docs.docker.com/install/linux/docker-ce/ubuntu/
    info "Removing conflicting Docker packages."
    apt-get -y remove containerd \
        docker \
        docker-compose \
        docker-engine \
        docker.io \
        runc > /dev/null 2>&1 || true
    run_script 'remove_snap_docker'
    run_script 'get_docker'
    notice "Installing docker compose plugin."
    local REDIRECT="> /dev/null 2>&1"
    if [[ -n ${VERBOSE:-} ]] || run_script 'question_prompt' "${PROMPT:-CLI}" N "Would you like to display the command output?"; then
        REDIRECT=""
    fi
    eval apt-get -y install docker-compose-plugin "${REDIRECT}" || fatal "Failed to install docker-compose-plugin from apt.\nFailing command: ${F[C]}apt-get -y install docker-compose-plugin"
}

test_pm_apt_install_docker() {
    run_script 'pm_apt_repos'
    run_script 'pm_apt_install_docker'
}
