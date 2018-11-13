#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

run_install() {
    info "Running installer."
    bash "${SCRIPTPATH}/main.sh" -i

    docker run hello-world || fatal "Failed to run docker hello-world."

    docker --version || fatal "Failed to determine docker version."
    docker-compose --version || fatal "Failed to determine docker-compose version."
    yq --version || fatal "Failed to determine yq version."
    info "Install test complete."
}
