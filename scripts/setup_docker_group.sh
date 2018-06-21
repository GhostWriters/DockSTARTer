#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

setup_docker_group() {
    # # https://docs.docker.com/install/linux/linux-postinstall/
    groupadd docker || true
    usermod -aG docker "${USER}"
}
