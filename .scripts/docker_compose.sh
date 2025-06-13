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

    local Title="Docker Compose"

    local Question YesNotice NoNotice
    local CommandNotice CommandNotice2
    local ComposeCommand ComposeCommand2
    case ${Command} in
        down)
            Question="Stop and remove ${AppName:-containers, networks, volumes, and images created by DockSTARTer}?"
            NoNotice="Not stopping and removing ${AppName:-containers, networks, volumes, and images created by DockSTARTer}."
            YesNotice="Stopping and removing ${AppName:-containers, networks, volumes, and images created by DockSTARTer}."
            ComposeCommand="down --remove-orphans ${APPNAME-}"
            ;;
        pull)
            Question="Pull the latest images for ${AppName:-all enabled services}?"
            NoNotice="Not pulling the latest images for ${AppName:-all enabled services}."
            YesNotice="Pulling the latest images for ${AppName:-all enabled services}."
            ComposeCommand="pull --include-deps ${APPNAME-}"
            ;;
        restart)
            Question="Restart ${AppName:-all stopped and running services}?"
            NoNotice="Not restarting ${AppName:-all stopped and running services}."
            YesNotice="Restarting ${AppName:-all stopped and running services}."
            ComposeCommand="restart ${APPNAME-}"
            ;;
        update)
            Question="Update ${AppName:-containers for all enabled services}?"
            NoNotice="Not updating ${AppName:-containers for all enabled services}."
            YesNotice="Updating ${AppName:-containers for all enabled services}."
            CommandNotice="Pulling the latest images for ${AppName:-all enabled services}."
            ComposeCommand="pull --include-deps ${APPNAME-}"
            CommandNotice2="Starting ${AppName:-containers for all enabled services}."
            ComposeCommand2="up -d --remove-orphans ${APPNAME-}"
            ;;
        up)
            Question="Start ${AppName:-containers for all enabled services}?"
            NoNotice="Not starting ${AppName:-containers for all enabled services}."
            YesNotice="Starting ${AppName:-containers for all enabled services}."
            ComposeCommand="up -d --remove-orphans ${APPNAME-}"
            ;;
        *)
            Question="Update containers for all enabled services?"
            NoNotice="Not updating containers for all enabled services."
            YesNotice="Updating containers for all enabled services."
            CommandNotice="Pulling the latest images for all enabled services."
            ComposeCommand="pull --include-deps"
            CommandNotice2="Starting containers for all enabled services."
            ComposeCommand2="up -d --remove-orphans"
            ;;
    esac
    if run_script 'question_prompt' Y "${Question}" "${DC["TitleWarning"]}${Title}" "${FORCE:+Y}"; then
        [[ -n ${YesNotice-} ]] && notice "${YesNotice}"
        run_script 'require_docker'
        [[ -n ${CommandNotice-} ]] && notice "${CommandNotice}"
        eval "docker compose --project-directory ${COMPOSE_FOLDER}/ ${ComposeCommand}" ||
            fatal "Failed to run compose.\nFailing command: ${F[C]}docker compose --project-directory ${COMPOSE_FOLDER}/ ${ComposeCommand}"
        if [[ -n ${ComposeCommand2-} ]]; then
            [[ -n ${CommandNotice2-} ]] && notice "${CommandNotice2}"
            eval "docker compose --project-directory ${COMPOSE_FOLDER}/ ${ComposeCommand2}" ||
                fatal "Failed to run compose.\nFailing command: ${F[C]}docker compose --project-directory ${COMPOSE_FOLDER}/ ${ComposeCommand2}"
        fi
    else
        [[ -n ${NoNotice-} ]] && notice "${NoNotice}"
    fi
}

test_docker_compose() {
    run_script 'appvars_create' WATCHTOWER
    cat "${COMPOSE_ENV}"
    run_script 'yml_merge'
    eval "docker compose --project-directory ${COMPOSE_FOLDER}/ config" || fatal "Failed to display compose config.\nFailing command: ${F[C]}docker compose --project-directory ${COMPOSE_FOLDER}/ config"
    run_script 'docker_compose'
}
