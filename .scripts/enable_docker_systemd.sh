#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

enable_docker_systemd() {
    # https://docs.docker.com/install/linux/linux-postinstall/
    if [[ -L "/sbin/init" ]]; then
        info "Systemd detected. Enabling docker service."
        run_cmd systemctl enable docker || fatal "Failed to enable docker service."
        run_cmd systemctl stop docker || true
        run_cmd systemctl start docker || fatal "Failed to start docker service."
    fi
}
