#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

install_compose() {
    # # https://docs.docker.com/compose/install/ OR https://github.com/javabean/arm-compose
    local AVAILABLE_COMPOSE
    if [[ ${ARCH} == "arm64" ]] || [[ ${ARCH} == "armhf" ]]; then
        AVAILABLE_COMPOSE=$(curl -H "${GH_HEADER:-}" -s "https://api.github.com/repos/javabean/arm-compose/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")')
        curl -H "${GH_HEADER:-}" -L "https://github.com/javabean/arm-compose/releases/download/${AVAILABLE_COMPOSE}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    fi
    if [[ ${ARCH} == "amd64" ]]; then
        AVAILABLE_COMPOSE=$(curl -H "${GH_HEADER:-}" -s "https://api.github.com/repos/docker/compose/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")')
        curl -H "${GH_HEADER:-}" -L "https://github.com/docker/compose/releases/download/${AVAILABLE_COMPOSE}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    fi
    chmod +x /usr/local/bin/docker-compose
}
