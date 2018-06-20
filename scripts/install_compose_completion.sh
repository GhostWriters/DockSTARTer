#!/bin/bash

install_compose_completion() {
    # # https://docs.docker.com/compose/completion/
    local AVAILABLE_COMPOSE_COMPLETION
    AVAILABLE_COMPOSE_COMPLETION=$(curl -H "${GH_HEADER}" -s "https://api.github.com/repos/docker/compose/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")')
    curl -H "${GH_HEADER}" -L "https://raw.githubusercontent.com/docker/compose/${AVAILABLE_COMPOSE_COMPLETION}/contrib/completion/bash/docker-compose" -o /etc/bash_completion.d/docker-compose
}
