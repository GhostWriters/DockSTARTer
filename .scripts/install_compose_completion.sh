#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

install_compose_completion() {
    # https://docs.docker.com/compose/completion/
    local AVAILABLE_COMPOSE_COMPLETION
    AVAILABLE_COMPOSE_COMPLETION=$( (curl -H "${GH_HEADER:-}" -fsL "https://api.github.com/repos/docker/compose/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")') || echo "0")
    if [[ ${AVAILABLE_COMPOSE_COMPLETION} == "0" ]]; then
        warning "Failed to check latest available docker-compose completion version. This can be ignored for now."
        return
    fi
    info "Installing docker-compose completion."
    curl -fsL "https://raw.githubusercontent.com/docker/compose/${AVAILABLE_COMPOSE_COMPLETION}/contrib/completion/bash/docker-compose" -o /etc/bash_completion.d/docker-compose > /dev/null 2>&1 || fatal "Failed to install docker-compose completion."
}

test_install_compose_completion() {
    run_script 'install_compose_completion'
}
