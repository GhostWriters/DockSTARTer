#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

docker_compose() {
    local COMPOSEINPUT=${1:-}
    local COMMAND=${COMPOSEINPUT%% *}
    local APPNAME
    if [[ ${COMPOSEINPUT} == *" "* ]]; then
        APPNAME=${COMPOSEINPUT#* }
    fi
    local COMPOSECOMMAND
    local COMMANDINFO
    case ${COMMAND} in
        down)
            COMPOSECOMMAND="down --remove-orphans"
            COMMANDINFO="Stopping and removing containers, networks, volumes, and images created by DockSTARTer."
            ;;
        pull)
            COMPOSECOMMAND="pull --include-deps ${APPNAME:-}"
            COMMANDINFO="Pulling the latest images for ${APPNAME:-all enabled services}."
            ;;
        restart)
            COMPOSECOMMAND="restart ${APPNAME:-}"
            COMMANDINFO="Restarting ${APPNAME:-all stopped and running services}."
            ;;
        up)
            COMPOSECOMMAND="up -d --remove-orphans ${APPNAME:-}"
            COMMANDINFO="Creating ${APPNAME:-containers for all enabled services}."
            ;;
        *)
            COMPOSECOMMAND="up -d --remove-orphans"
            COMMANDINFO="Creating containers for all enabled services."
            ;;
    esac
    if run_script 'question_prompt' "${PROMPT:-}" Y "Would you like to run compose now?"; then
        info "${COMMANDINFO}"
    else
        info "Compose will not be run."
        return 1
    fi
    run_script 'install_docker'
    local MKTEMP_RUN_COMPOSE
    MKTEMP_RUN_COMPOSE=$(mktemp) || fatal "Failed to create temporary run compose script.\nFailing command: ${F[C]}mktemp"
    info "Downloading run compose script."
    curl -fsSL https://raw.githubusercontent.com/linuxserver/docker-docker-compose/master/run.sh -o "${MKTEMP_RUN_COMPOSE}" > /dev/null 2>&1 || fatal "Failed to get run compose script.\nFailing command: ${F[C]}curl -fsSL https://raw.githubusercontent.com/linuxserver/docker-docker-compose/master/run.sh -o \"${MKTEMP_RUN_COMPOSE}\""
    docker pull ghcr.io/linuxserver/docker-compose:latest || fatal "Failed to pull latest docker-compose image.\nFailing command: ${F[C]}docker pull ghcr.io/linuxserver/docker-compose:latest"
    cd "${SCRIPTPATH}/compose/" || fatal "Failed to change directory.\nFailing command: ${F[C]}cd \"${SCRIPTPATH}/compose/\""
    eval sh "${MKTEMP_RUN_COMPOSE}" "${COMPOSECOMMAND}" || fatal "Docker Compose failed.\nFailing command: ${F[C]}eval sh \"${MKTEMP_RUN_COMPOSE}\" \"${COMPOSECOMMAND}\""
    cd "${SCRIPTPATH}" || fatal "Failed to change directory.\nFailing command: ${F[C]}cd \"${SCRIPTPATH}\""
    rm -f "${MKTEMP_RUN_COMPOSE}" || warn "Failed to remove temporary run compose script."
}

test_docker_compose() {
    run_script 'appvars_create' WATCHTOWER
    cat "${SCRIPTPATH}/compose/.env"
    run_script 'yml_merge'
    cd "${SCRIPTPATH}/compose/" || fatal "Failed to change directory.\nFailing command: ${F[C]}cd \"${SCRIPTPATH}/compose/\""
    local MKTEMP_RUN_COMPOSE
    MKTEMP_RUN_COMPOSE=$(mktemp) || fatal "Failed to create temporary run compose script.\nFailing command: ${F[C]}mktemp"
    info "Downloading run compose script."
    curl -fsSL https://raw.githubusercontent.com/linuxserver/docker-docker-compose/master/run.sh -o "${MKTEMP_RUN_COMPOSE}" > /dev/null 2>&1 || fatal "Failed to get run compose script.\nFailing command: ${F[C]}curl -fsSL https://raw.githubusercontent.com/linuxserver/docker-docker-compose/master/run.sh -o \"${MKTEMP_RUN_COMPOSE}\""
    docker pull ghcr.io/linuxserver/docker-compose:latest || fatal "Failed to pull latest docker-compose image.\nFailing command: ${F[C]}docker pull ghcr.io/linuxserver/docker-compose:latest"
    eval sh "${MKTEMP_RUN_COMPOSE}" config || fatal "Failed to validate ${SCRIPTPATH}/compose/docker-compose.yml file.\nFailing command: ${F[C]}eval sh \"${MKTEMP_RUN_COMPOSE}\" config"
    rm -f "${MKTEMP_RUN_COMPOSE}" || warn "Failed to remove temporary run compose script."
    cd "${SCRIPTPATH}" || fatal "Failed to change directory.\nFailing command: ${F[C]}cd \"${SCRIPTPATH}\""
    run_script 'docker_compose'
}
