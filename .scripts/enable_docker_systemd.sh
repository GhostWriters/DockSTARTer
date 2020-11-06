#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

enable_docker_systemd() {
    # https://docs.docker.com/install/linux/linux-postinstall/
    if [[ -L "/sbin/init" ]]; then
        info "Systemd detected. Enabling docker service."
        systemctl enable docker > /dev/null 2>&1 || fatal "Failed to enable docker service.\nFailing command: ${F[C]}systemctl enable docker"
        info "Starting docker service."
        systemctl start docker > /dev/null 2>&1 || fatal "Failed to start docker service.\nFailing command: ${F[C]}systemctl start docker"
    fi
}

test_enable_docker_systemd() {
    run_script 'install_docker'
    run_script 'enable_docker_systemd'
}
