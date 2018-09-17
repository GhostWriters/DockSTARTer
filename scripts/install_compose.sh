#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

install_compose() {
    # https://docs.docker.com/compose/install/ OR https://github.com/javabean/arm-compose
    local AVAILABLE_COMPOSE
    AVAILABLE_COMPOSE=$(curl -H "${GH_HEADER:-}" -s "https://api.github.com/repos/docker/compose/releases/latest" | grep -Po '"tag_name": "[Vv]?\K.*?(?=")')
    local INSTALLED_COMPOSE
    INSTALLED_COMPOSE=$( (docker-compose --version 2> /dev/null || true) | sed -E 's/.* version ([^,]*)(, build .*)?/\1/')
    local FORCE
    FORCE=${1:-}
    if [[ "${AVAILABLE_COMPOSE}" != "${INSTALLED_COMPOSE}" ]] || [[ -n ${FORCE} ]]; then
        info "Installing latest compose."
        if [[ -n "$(command -v yum)" ]] || [[ ${ARCH} == "aarch64" ]] || [[ ${ARCH} == "armv7l" ]]; then
            if [[ -n "$(command -v apt)" ]]; then
                apt-get -y remove docker-compose > /dev/null 2>&1
                apt-get -y install python-pip > /dev/null 2>&1
            fi
            if [[ -n "$(command -v yum)" ]]; then
                yum -y install epel-release > /dev/null 2>&1
                yum -y install python-pip > /dev/null 2>&1
                yum -y upgrade python* > /dev/null 2>&1
            fi
            pip install -U pip > /dev/null 2>&1
            pip uninstall docker-py > /dev/null 2>&1 || true
            pip install -U setuptools > /dev/null 2>&1
            pip install -U docker-compose > /dev/null 2>&1
        fi
        if [[ ${ARCH} == "x86_64" ]]; then
            curl -H "${GH_HEADER:-}" -L "https://github.com/docker/compose/releases/download/${AVAILABLE_COMPOSE}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose > /dev/null 2>&1
            chmod +x /usr/local/bin/docker-compose > /dev/null 2>&1 || true
            if [[ -n "$(command -v dnf)" ]]; then
                dnf -y install docker-compose > /dev/null 2>&1
            fi
        fi
    fi
}
