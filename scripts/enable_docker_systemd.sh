#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

enable_docker_systemd() {
    # https://docs.docker.com/install/linux/linux-postinstall/
    if [[ ${ISSYSTEMD} == true ]]; then
        info "Systemd detected. Enabling docker service."
        systemctl enable docker > /dev/null 2>&1
    fi
}
