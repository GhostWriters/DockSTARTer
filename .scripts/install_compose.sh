#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

install_compose() {
    local MINIMUM_COMPOSE="1.17.0"
    # Find minimum compatible version at https://docs.docker.com/release-notes/docker-compose/
    local INSTALLED_COMPOSE
    if [[ ${FORCE:-} == true ]] && [[ -n ${INSTALL:-} ]]; then
        INSTALLED_COMPOSE="0"
    else
        INSTALLED_COMPOSE=$( (docker-compose --version 2> /dev/null || echo "0") | sed -E 's/.* version ([^,]*)(, build .*)?/\1/')
    fi
    if vergt "${MINIMUM_COMPOSE}" "${INSTALLED_COMPOSE}"; then
        local AVAILABLE_COMPOSE
        AVAILABLE_COMPOSE=$( (curl -H "${GH_HEADER:-}" -fsL "https://api.github.com/repos/docker/compose/releases/latest" | grep -Po '"tag_name": "[Vv]?\K.*?(?=")') || echo "0")
        if [[ ${AVAILABLE_COMPOSE} == "0" ]]; then
            if [[ ${INSTALLED_COMPOSE} == "0" ]]; then
                fatal "The latest available version of docker-compose could not be confirmed. This is usually caused by exhausting the rate limit on GitHub's API. Please check https://api.github.com/rate_limit"
            else
                warn "Failed to check latest available docker-compose version. This can be ignored for now."
                return
            fi
        fi
        if vergt "${AVAILABLE_COMPOSE}" "${INSTALLED_COMPOSE}"; then
            info "Removing previous docker-compose image."
            docker image rm linuxserver/docker-compose:latest || true
            # https://github.com/linuxserver/docker-docker-compose/blob/master/README.md#recommended-method
            info "Installing latest docker-compose."
            curl -fsL "https://raw.githubusercontent.com/linuxserver/docker-docker-compose/master/run.sh" -o /usr/local/bin/docker-compose > /dev/null 2>&1 || fatal "Failed to install docker-compose."
            chmod +x /usr/local/bin/docker-compose > /dev/null 2>&1 || true
            if [[ ! -L "/usr/bin/docker-compose" ]]; then
                rm -f /usr/bin/docker-compose || warn "Failed to remove /usr/bin/docker-compose"
                ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose || fatal "Failed to create /usr/bin/docker-compose symlink."
            fi
            local UPDATED_COMPOSE
            UPDATED_COMPOSE=$( (docker-compose --version 2> /dev/null || echo "0") | sed -E 's/.* version ([^,]*)(, build .*)?/\1/')
            if vergt "${AVAILABLE_COMPOSE}" "${UPDATED_COMPOSE}"; then
                error "Failed to install the latest docker-compose."
            fi
            if vergt "${MINIMUM_COMPOSE}" "${UPDATED_COMPOSE}"; then
                fatal "Failed to install the minimum required docker-compose."
            fi
        fi
    fi
}

test_install_compose() {
    run_script 'install_compose'
    docker-compose --version || fatal "Failed to determine docker-compose version."
}
