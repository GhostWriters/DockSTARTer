#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

setup_docker_group() {
    # # https://docs.docker.com/install/linux/linux-postinstall/
    info "Creating docker group."
    groupadd docker > /dev/null 2>&1 || true
    info "Adding ${USER} to docker group."
    usermod -aG docker "${USER}"
}
