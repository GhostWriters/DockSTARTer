#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

run_compose() {
    local COMMAND
    COMMAND=${1:-}
    local COMPOSECOMMAND
    local COMMANDINFO
    case ${COMMAND} in
        down)
            COMPOSECOMMAND="down --remove-orphans"
            COMMANDINFO="Stopping and removing containers, networks, volumes, and images created by DockSTARTer."
            ;;
        pull)
            COMPOSECOMMAND="pull --include-deps"
            COMMANDINFO="Pulling the latest images for all enabled services."
            ;;
        restart)
            COMPOSECOMMAND="restart"
            COMMANDINFO="Restarting all stopped and running services."
            ;;
        up)
            COMPOSECOMMAND="up -d --remove-orphans"
            COMMANDINFO="Creating containers for all enabled services."
            ;;
        *)
            COMPOSECOMMAND="up -d --remove-orphans"
            COMMANDINFO="Creating containers for all enabled services."
            ;;
    esac
    if run_script 'question_prompt' Y "Would you like to run compose now?"; then
        info "${COMMANDINFO}"
    else
        info "Compose will not be run."
        return 1
    fi
    run_script 'install_docker'
    run_script 'install_compose'
    cd "${SCRIPTPATH}/compose/" || fatal "Failed to change directory to ${SCRIPTPATH}/compose/"
    eval docker-compose "${COMPOSECOMMAND}" || fatal "Docker Compose failed."
    cd "${SCRIPTPATH}" || fatal "Failed to change directory to ${SCRIPTPATH}"
}

test_run_compose() {
    run_script 'generate_yml'
    run_script 'run_compose'
    cd "${SCRIPTPATH}/compose/" || fatal "Failed to change to ${SCRIPTPATH}/compose/ directory."
    docker-compose config || fatal "Failed to validate ${SCRIPTPATH}/compose/docker-compose.yml file."
    cd "${SCRIPTPATH}" || fatal "Failed to change to ${SCRIPTPATH} directory."
}
