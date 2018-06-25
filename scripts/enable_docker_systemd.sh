#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

enable_docker_systemd() {
    # # https://docs.docker.com/install/linux/linux-postinstall/
    if [[ ${ISSYSTEMD} == true ]]; then
        systemctl enable docker
    fi
}
