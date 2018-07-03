#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

install_docker() {
    # # https://github.com/docker/docker-install
    local AVAILABLE_DOCKER
    AVAILABLE_DOCKER=$(curl -H "${GH_HEADER:-}" -s "https://api.github.com/repos/docker/docker-ce/releases/latest" | grep -Po '"tag_name": "[Vv]?\K.*?(?=")')
    local INSTALLED_DOCKER
    INSTALLED_DOCKER=$( (docker --version || true) | sed -E 's/.* version ([^,]*)(, build .*)?/\1/')
    local FORCE
    FORCE=${1:-}
    if [[ "${AVAILABLE_DOCKER}" != "${INSTALLED_DOCKER}" ]] || [[ -n ${FORCE} ]]; then
        curl -fsSL get.docker.com -o get-docker.sh
        sh get-docker.sh
        trap 'rm -f get-docker.sh' EXIT
    fi
}
