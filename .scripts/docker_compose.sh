#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

docker_compose() {
    local Title="Docker Compose"
    local COMPOSEINPUT=${1-}
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
            COMPOSECOMMAND="pull --include-deps ${APPNAME-}"
            COMMANDINFO="Pulling the latest images for ${APPNAME:-all enabled services}."
            ;;
        restart)
            COMPOSECOMMAND="restart ${APPNAME-}"
            COMMANDINFO="Restarting ${APPNAME:-all stopped and running services}."
            ;;
        up)
            COMPOSECOMMAND="up -d --remove-orphans ${APPNAME-}"
            COMMANDINFO="Creating ${APPNAME:-containers for all enabled services}."
            ;;
        *)
            COMPOSECOMMAND="up -d --remove-orphans"
            COMMANDINFO="Creating containers for all enabled services."
            ;;
    esac
    info "${COMMANDINFO}"
    run_script 'require_docker'
    local REDIRECT=""
    if [[ ${PROMPT:-CLI} == GUI ]]; then
        REDIRECT="2>&1 | dialog --clear --title \"${Title}\" --programbox \"\${RUNCOMMAND}\" -1 -1"
    fi
    local RUNCOMMAND="docker compose --project-directory ${COMPOSE_FOLDER}/ ${COMPOSECOMMAND}"
    eval "${RUNCOMMAND} ${REDIRECT}" || fatal "Failed to run compose.\nFailing command: ${F[C]}${RUNCOMMAND}"
}

test_docker_compose() {
    run_script 'appvars_create' WATCHTOWER
    cat "${COMPOSE_ENV}"
    run_script 'yml_merge'
    eval "docker compose --project-directory ${COMPOSE_FOLDER}/ config" || fatal "Failed to display compose config.\nFailing command: ${F[C]}docker compose --project-directory ${COMPOSE_FOLDER}/ config"
    run_script 'docker_compose'
}
