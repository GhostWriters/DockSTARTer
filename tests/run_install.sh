#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

run_install() {
    info "Running installer."
    bash "${SCRIPTPATH}/main.sh" -xi

    yq --version || fatal "Could not determine yq version."
    docker run hello-world || fatal "Could not run docker hello-world."
    docker-compose --version || fatal "Could not determine docker-compose version."
}
