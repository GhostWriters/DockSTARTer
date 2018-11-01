#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

run_install() {
    info "Running installer."
    bash "${SCRIPTPATH}/main.sh" -i

    yq --version || fatal "Failed to determine yq version."
    docker run hello-world || fatal "Failed to run docker hello-world."
    docker-compose --version || fatal "Failed to determine docker-compose version."
    info "Install test complete."
}
