#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

run_generate_slim() {
    run_script 'update_system'
    info "Running compose."
    run_cmd bash "${SCRIPTPATH}/main.sh" -c
    run_cmd cd "${SCRIPTPATH}/compose/" || fatal "Failed to change to ${SCRIPTPATH}/compose/ directory."
    run_cmd docker-compose config || fatal "Failed to validate ${SCRIPTPATH}/compose/docker-compose.yml file."
    echo
    run_cmd docker-compose up -d --remove-orphans || fatal "Docker Compose failed."
    run_cmd cd "${SCRIPTPATH}" || fatal "Failed to change to ${SCRIPTPATH} directory."
    info "Generator test complete."
}
