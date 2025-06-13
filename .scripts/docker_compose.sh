#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

docker_compose() {
    local ComposeInput=${1-}
    local Command=${ComposeInput%% *}
    local APPNAME
    local AppName
    if [[ ${ComposeInput} == *" "* ]]; then
        APPNAME=${ComposeInput#* }
        AppName="$(run_script 'app_nicename' "${APPNAME}")"
    fi
    local ComposeCommand ComposeCommand2
    local CommandNotice
    case ${Command} in
        down)
            ComposeCommand="down --remove-orphans ${APPNAME-}"
            CommandNotice="Stopping and removing ${AppName:-containers, networks, volumes, and images created by DockSTARTer}."
            ;;
        pull)
            ComposeCommand="pull --include-deps ${APPNAME-}"
            CommandNotice="Pulling the latest images for ${AppName:-all enabled services}."
            ;;
        restart)
            ComposeCommand="restart ${APPNAME-}"
            CommandNotice="Restarting ${AppName:-all stopped and running services}."
            ;;
        update)
            ComposeCommand="pull --include-deps ${APPNAME-}"
            CommandNotice="Pulling the latest images for ${AppName:-all enabled services}."
            ComposeCommand2="up -d --remove-orphans ${APPNAME-}"
            CommandNotice2="Starting ${AppName:-containers for all enabled services}."
            ;;
        up)
            ComposeCommand="up -d --remove-orphans ${APPNAME-}"
            CommandNotice="Starting ${AppName:-containers for all enabled services}."
            ;;
        *)
            ComposeCommand="up -d --remove-orphans"
            CommandNotice="Creating containers for all enabled services."
            ;;
    esac
    run_script 'require_docker'
    notice "${CommandNotice}"
    eval "docker compose --project-directory ${COMPOSE_FOLDER}/ ${ComposeCommand}" ||
        fatal "Failed to run compose.\nFailing command: ${F[C]}docker compose --project-directory ${COMPOSE_FOLDER}/ ${ComposeCommand}"
    if [[ -n ${ComposeCommand2-} ]]; then
        notice "${CommandNotice2}"
        eval "docker compose --project-directory ${COMPOSE_FOLDER}/ ${ComposeCommand2}" ||
            fatal "Failed to run compose.\nFailing command: ${F[C]}docker compose --project-directory ${COMPOSE_FOLDER}/ ${ComposeCommand2}"
    fi
}

test_docker_compose() {
    run_script 'appvars_create' WATCHTOWER
    cat "${COMPOSE_ENV}"
    run_script 'yml_merge'
    eval "docker compose --project-directory ${COMPOSE_FOLDER}/ config" || fatal "Failed to display compose config.\nFailing command: ${F[C]}docker compose --project-directory ${COMPOSE_FOLDER}/ config"
    run_script 'docker_compose'
}
