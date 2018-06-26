#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

install_docker() {
    # # https://github.com/docker/docker-install
    local AVAILABLE_DOCKER
    AVAILABLE_DOCKER=$(curl -H "${GH_HEADER:-}" -s "https://api.github.com/repos/docker/docker-ce/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")')
    if ! docker --version &>/dev/null || true | grep "${AVAILABLE_DOCKER:1}"; then
        curl -fsSL get.docker.com -o get-docker.sh
        sh get-docker.sh
        trap 'rm -f get-docker.sh' EXIT
    fi
}
