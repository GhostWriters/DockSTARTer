#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

install_docker() {
    # # https://github.com/docker/docker-install
    curl -fsSL get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
}
