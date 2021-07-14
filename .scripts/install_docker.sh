#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

install_docker() {
    local MINIMUM_DOCKER="19.03.0"
    # Find minimum compatible version at https://docs.docker.com/engine/release-notes/
    local INSTALLED_DOCKER
    if [[ ${FORCE:-} == true ]] && [[ -n ${INSTALL:-} ]]; then
        INSTALLED_DOCKER="0"
    else
        INSTALLED_DOCKER=$( (docker --version 2> /dev/null || echo "0") | sed -E 's/(\S+ )(version )?([0-9][a-zA-Z0-9_.-]*)(, build .*)?/\3/')
    fi
    if vergt "${MINIMUM_DOCKER}" "${INSTALLED_DOCKER}"; then
        run_script 'package_manager_run' install_docker
    fi
}

test_install_docker() {
    run_script 'install_docker'
    docker --version || fatal "Failed to determine docker version.\nFailing command: ${F[C]}docker --version"
}
