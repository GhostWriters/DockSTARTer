#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

docker_compose() {
    local COMPOSEINPUT=${1-}
    local COMMAND=${COMPOSEINPUT%% *}
    local APPNAME
    local AppName
    if [[ ${COMPOSEINPUT} == *" "* ]]; then
        APPNAME=${COMPOSEINPUT#* }
        AppName="$(run_script 'app_nicename' "${APPNAME}")"
    fi
    local COMPOSECOMMAND COMPOSECOMMAND2
    local COMMANDINFO
    case ${COMMAND} in
        down)
            COMPOSECOMMAND="down --remove-orphans ${APPNAME-}"
            COMMANDINFO="Stopping and removing ${AppName:-containers, networks, volumes, and images created by DockSTARTer}."
            ;;
        pull)
            COMPOSECOMMAND="pull --include-deps ${APPNAME-}"
            COMMANDINFO="Pulling the latest images for ${AppName:-all enabled services}."
            ;;
        restart)
            COMPOSECOMMAND="restart ${APPNAME-}"
            COMMANDINFO="Restarting ${AppName:-all stopped and running services}."
            ;;
        update)
            COMPOSECOMMAND="pull --include-deps ${APPNAME-}"
            COMPOSECOMMAND2="up -d --remove-orphans ${APPNAME-}"
            COMMANDINFO="Updating ${AppName:-containers for all enabled services}."
            ;;
        up)
            COMPOSECOMMAND="up -d --remove-orphans ${APPNAME-}"
            COMMANDINFO="Creating ${AppName:-containers for all enabled services}."
            ;;
        *)
            COMPOSECOMMAND="up -d --remove-orphans"
            COMMANDINFO="Creating containers for all enabled services."
            ;;
    esac
    info "${COMMANDINFO}"
    run_script 'require_docker'
    eval "docker compose --project-directory ${COMPOSE_FOLDER}/ ${COMPOSECOMMAND}" ||
        fatal "Failed to run compose.\nFailing command: ${F[C]}docker compose --project-directory ${COMPOSE_FOLDER}/ ${COMPOSECOMMAND}"
    if [[ -n ${COMPOSECOMMAND2-} ]]; then
        eval "docker compose --project-directory ${COMPOSE_FOLDER}/ ${COMPOSECOMMAND2}" ||
            fatal "Failed to run compose.\nFailing command: ${F[C]}docker compose --project-directory ${COMPOSE_FOLDER}/ ${COMPOSECOMMAND2}"
    fi
}

test_docker_compose() {
    run_script 'appvars_create' WATCHTOWER
    cat "${COMPOSE_ENV}"
    run_script 'yml_merge'
    eval "docker compose --project-directory ${COMPOSE_FOLDER}/ config" || fatal "Failed to display compose config.\nFailing command: ${F[C]}docker compose --project-directory ${COMPOSE_FOLDER}/ config"
    run_script 'docker_compose'
}
