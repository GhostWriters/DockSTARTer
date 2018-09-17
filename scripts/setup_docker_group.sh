#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

setup_docker_group() {
    # https://docs.docker.com/install/linux/linux-postinstall/
    # https://github.com/jenkinsci/docker/issues/196#issuecomment-179486312
    local DOCKER_SOCKET=/var/run/docker.sock
    local DOCKER_GROUP=docker

    if [[ -S ${DOCKER_SOCKET} ]]; then
        DOCKER_GID=$(stat -c '%g' ${DOCKER_SOCKET})
        info "Creating ${DOCKER_GROUP} group."
        groupadd -for -g "${DOCKER_GID}" "${DOCKER_GROUP}" > /dev/null 2>&1 || fatal "Could not create ${DOCKER_GROUP} group."
        if [[ ${CI:-} == true ]] && [[ ${TRAVIS:-} == true ]]; then
            info "Skipping usermod on Travis."
        else
            info "Adding ${DETECTED_UNAME} to ${DOCKER_GROUP} group."
            usermod -aG "${DOCKER_GROUP}" "${DETECTED_UNAME}" > /dev/null 2>&1 || fatal "Could not add ${DETECTED_UNAME} to ${DOCKER_GROUP} group."
        fi
        info "Setting DOCKERGID to ${DOCKER_GID} in ${SCRIPTPATH}/compose/.env file."
        run_script 'env_create'
        run_script 'env_set' "DOCKERGID" "${DOCKER_GID}"
    else
        fatal "Docker is not installed correctly. Please retry the installation."
    fi
}
