#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

install_compose() {
    # # https://docs.docker.com/compose/install/ OR https://github.com/javabean/arm-compose
    local AVAILABLE_COMPOSE
    AVAILABLE_COMPOSE=$(curl -H "${GH_HEADER:-}" -s "https://api.github.com/repos/docker/compose/releases/latest" | grep -Po '"tag_name": "[Vv]?\K.*?(?=")')
    local INSTALLED_COMPOSE
    INSTALLED_COMPOSE=$( (docker-compose --version || true) | sed -E 's/.* version ([^,]*)(, build .*)?/\1/')
    local FORCE
    FORCE=${1:-}
    if [[ "${AVAILABLE_COMPOSE}" != "${INSTALLED_COMPOSE}" ]] || [[ -n ${FORCE} ]]; then
        if [[ ${ARCH} == "arm64" ]] || [[ ${ARCH} == "armhf" ]]; then
            apt-get remove docker-compose
            apt-get -y install python-pip
            pip uninstall docker-py
            pip install -U docker-compose
        fi
        if [[ ${ARCH} == "amd64" ]]; then
            curl -H "${GH_HEADER:-}" -L "https://github.com/docker/compose/releases/download/${AVAILABLE_COMPOSE}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
            chmod +x /usr/local/bin/docker-compose || true
        fi
    fi
}
