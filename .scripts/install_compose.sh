#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

install_compose() {
    # https://docs.docker.com/compose/install/
    local AVAILABLE_COMPOSE
    AVAILABLE_COMPOSE=$( (curl -H "${GH_HEADER:-}" -fsL "https://api.github.com/repos/docker/compose/releases/latest" | grep -Po '"tag_name": "[Vv]?\K.*?(?=")') || echo "0")
    local INSTALLED_COMPOSE
    INSTALLED_COMPOSE=$( (docker-compose --version 2> /dev/null || echo "0") | sed -E 's/.* version ([^,]*)(, build .*)?/\1/')
    local FORCE
    FORCE=${1:-}
    if [[ ${AVAILABLE_COMPOSE} == "0" ]]; then
        if [[ ${INSTALLED_COMPOSE} == "0" ]] || [[ -n ${FORCE} ]]; then
            fatal "The latest available version of docker-compose could not be confirmed. This is usually caused by exhausting the rate limit on GitHub's API. Please check https://api.github.com/rate_limit"
        else
            warning "Failed to check latest available docker-compose version. This can be ignored for now."
            return
        fi
    fi
    if vergt "${AVAILABLE_COMPOSE}" "${INSTALLED_COMPOSE}" || [[ -n ${FORCE} ]]; then
        info "Installing latest python pip."
        run_script 'run_python' -m pip install -IUq pip > /dev/null 2>&1 || warning "Failed to install pip from pip. This can be ignored for now."

        info "Removing old docker-compose."
        rm /usr/local/bin/docker-compose > /dev/null 2>&1 || true
        rm /usr/bin/docker-compose > /dev/null 2>&1 || true
        run_script 'run_python' -m pip uninstall docker-py > /dev/null 2>&1 || true

        info "Installing latest docker-compose."
        run_script 'run_python' -m pip install -IUq setuptools > /dev/null 2>&1 || warning "Failed to install setuptools from pip. This can be ignored for now."
        run_script 'run_python' -m pip install -IUq "urllib3[secure]" > /dev/null 2>&1 || warning "Failed to install urllib3[secure] from pip. This can be ignored for now."
        run_script 'run_python' -m pip install -IUq docker-compose > /dev/null 2>&1 || warning "Failed to install docker-compose from pip. This can be ignored for now."

        local UPDATED_COMPOSE
        UPDATED_COMPOSE=$( (docker-compose --version 2> /dev/null || echo "0") | sed -E 's/.* version ([^,]*)(, build .*)?/\1/')
        if vergt "${AVAILABLE_COMPOSE}" "${UPDATED_COMPOSE}"; then
            fatal "Failed to install the latest docker-compose."
        fi
    fi
}

test_install_compose() {
    run_script 'install_compose'
    docker-compose --version || fatal "Failed to determine docker-compose version."
}
