#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

require_docker() {
    if run_script 'needs_install_docker'; then
        run_script 'package_manager_run' install_docker
    fi
}

test_require_docker() {
    run_script 'require_docker'
    docker --version ||
        fatal \
            "Failed to determine docker version.\n" \
            "Failing command: ${C["FailingCommand"]}docker --version"
    docker compose version ||
        fatal \
            "Failed to determine docker compose version.\n" \
            "Failing command: ${C["FailingCommand"]}docker compose version"
}
