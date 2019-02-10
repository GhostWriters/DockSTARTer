#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

install_compose() {
    # https://docs.docker.com/compose/install/
    local AVAILABLE_COMPOSE
    AVAILABLE_COMPOSE=$(curl -H "${GH_HEADER:-}" -s "https://api.github.com/repos/docker/compose/releases/latest" | grep -Po '"tag_name": "[Vv]?\K.*?(?=")') || fatal "Failed to check latest available docker-compose version."
    local INSTALLED_COMPOSE
    INSTALLED_COMPOSE=$( (docker-compose --version 2> /dev/null || true) | sed -E 's/.* version ([^,]*)(, build .*)?/\1/')
    local FORCE
    FORCE=${1:-}
    if [[ ${AVAILABLE_COMPOSE} != "${INSTALLED_COMPOSE}" ]] || [[ -n ${FORCE} ]]; then
        info "Removing old docker-compose."
        rm /usr/local/bin/docker-compose > /dev/null 2>&1 || true
        rm /usr/bin/docker-compose > /dev/null 2>&1 || true
        pip uninstall docker-py > /dev/null 2>&1 || true

        info "Installing latest docker-compose."
        pip install -IU setuptools > /dev/null 2>&1 || warning "Failed to install setuptools from pip."
        pip install -IU "urllib3[secure]" > /dev/null 2>&1 || warning "Failed to install urllib3[secure] from pip."
        pip install -IU docker-compose > /dev/null 2>&1 || fatal "Failed to install docker-compose from pip."

        local UPDATED_COMPOSE
        UPDATED_COMPOSE=$( (docker-compose --version 2> /dev/null || true) | sed -E 's/.* version ([^,]*)(, build .*)?/\1/')
        if [[ ${AVAILABLE_COMPOSE} != "${UPDATED_COMPOSE}" ]]; then
            fatal "Failed to install the latest docker-compose."
        fi
    fi
}
