#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_yum_install_docker() {
    # https://docs.docker.com/install/linux/docker-ce/centos/
    info "Removing conflicting Docker packages."
    yum -y remove docker \
        docker-client \
        docker-client-latest \
        docker-common \
        docker-compose \
        docker-engine \
        docker-latest \
        docker-latest-logrotate \
        docker-logrotate > /dev/null 2>&1 || true
    run_script 'remove_snap_docker'
    run_script 'get_docker'
    notice "Installing docker compose plugin."
    local REDIRECT="> /dev/null 2>&1"
    if [[ -n ${VERBOSE:-} ]] || run_script 'question_prompt' "${PROMPT:-CLI}" N "Would you like to display the command output?"; then
        REDIRECT=""
    fi
    eval yum -y install docker-compose-plugin "${REDIRECT}" || fatal "Failed to install docker-compose-plugin from yum.\nFailing command: ${F[C]}yum -y install docker-compose-plugin"
}

test_pm_yum_install_docker() {
    # run_script 'pm_yum_install_docker'
    warn "CI does not test pm_yum_install_docker."
}
