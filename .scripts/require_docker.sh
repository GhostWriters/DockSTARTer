#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

require_docker() {
    local MINIMUM_DOCKER="20.10.0"
    local MINIMUM_COMPOSE="2.3.0"
    # Find minimum compatible version at https://docs.docker.com/engine/release-notes/
    # Note compatibility from https://wiki.alpinelinux.org/wiki/Release_Notes_for_Alpine_3.14.0
    local INSTALLED_DOCKER
    local INSTALLED_COMPOSE
    if [[ ${FORCE-} == true ]] && [[ -n ${INSTALL-} ]]; then
        INSTALLED_DOCKER="0"
        INSTALLED_COMPOSE="0"
    else
        INSTALLED_DOCKER=$( (docker --version 2> /dev/null | grep --color=never -Po "Docker version \K([0-9][a-zA-Z0-9_.-]*)") || echo "0")
        INSTALLED_COMPOSE=$( (docker compose version 2> /dev/null | grep --color=never -Po "Docker Compose version v\K([0-9][a-zA-Z0-9_.-]*)") || echo "0")
    fi
    if vergt "${MINIMUM_DOCKER}" "${INSTALLED_DOCKER:-0}" || vergt "${MINIMUM_COMPOSE}" "${INSTALLED_COMPOSE:-0}"; then
        run_script 'package_manager_run' install_docker
    fi
}

test_require_docker() {
    run_script 'require_docker'
    docker --version || fatal "Failed to determine docker version.\nFailing command: ${F[C]}docker --version"
    docker compose version || fatal "Failed to determine docker compose version.\nFailing command: ${F[C]}docker compose version"
}
