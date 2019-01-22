#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

run_install() {
    info "Running installer."
    run_cmd bash "${SCRIPTPATH}/main.sh" -v 4 -i

    run_cmd docker run hello-world || fatal "Failed to run docker hello-world."

    run_cmd docker --version || fatal "Failed to determine docker version."
    run_cmd docker-compose --version || fatal "Failed to determine docker-compose version."
    run_cmd yq --version || fatal "Failed to determine yq version."
    info "Install test complete."
}
