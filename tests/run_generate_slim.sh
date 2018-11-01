#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

run_generate_slim() {
    run_script 'update_system'
    info "Running compose."
    bash "${SCRIPTPATH}/main.sh" -c
    echo
    cat "${SCRIPTPATH}/compose/docker-compose.yml" || fatal "${SCRIPTPATH}/compose/docker-compose.yml not found."
    echo
    cd "${SCRIPTPATH}/compose/" || fatal "Failed to change to ${SCRIPTPATH}/compose/ directory."
    docker-compose up -d || fatal "Docker Compose failed."
    cd "${SCRIPTPATH}" || fatal "Failed to change to ${SCRIPTPATH} directory."
    info "Generator test complete."
}
