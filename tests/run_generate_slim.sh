#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

run_generate_slim() {
    run_script 'update_system'
    run_script 'env_update'
    info "Running generator."
    bash "${SCRIPTPATH}/main.sh" -g
    echo
    cat "${SCRIPTPATH}/compose/docker-compose.yml" || fatal "${SCRIPTPATH}/compose/docker-compose.yml not found."
    echo
    cd "${SCRIPTPATH}/compose/" || fatal "Could not change to ${SCRIPTPATH}/compose/ directory."
    docker-compose up -d || fatal "Docker Compose failed."
    cd "${SCRIPTPATH}" || fatal "Could not change to ${SCRIPTPATH} directory."
}
