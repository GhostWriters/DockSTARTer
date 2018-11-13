#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

run_generate_slim() {
    run_script 'update_system'
    info "Running compose."
    bash "${SCRIPTPATH}/main.sh" -c
    cd "${SCRIPTPATH}/compose/" || fatal "Failed to change to ${SCRIPTPATH}/compose/ directory."
    docker-compose config || fatal "Failed to validate ${SCRIPTPATH}/compose/docker-compose.yml file."
    echo
    docker-compose up -d || fatal "Docker Compose failed."
    cd "${SCRIPTPATH}" || fatal "Failed to change to ${SCRIPTPATH} directory."
    info "Generator test complete."
}
