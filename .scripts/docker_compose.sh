#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

docker_compose() {
    local ComposeInput=${1-}
    ComposeInput="${ComposeInput//\n/ }"
    ComposeInput="$(xargs <<< "${ComposeInput}")"
    local Command=${ComposeInput%% *}
    local APPNAME AppName
    if [[ ${ComposeInput} == *" "* ]]; then
        APPNAME=${ComposeInput#* }
        AppName="$(run_script 'app_nicename' "${APPNAME}" | xargs)"
    fi

    local Title="Docker Compose"

    local Question YesNotice NoNotice
    local -a CommandNotice
    local -a ComposeCommand
    case ${Command} in
        down)
            Question="Stop and remove ${AppName:-containers, networks, volumes, and images created by DockSTARTer}?"
            NoNotice="Not stopping and removing ${AppName:-containers, networks, volumes, and images created by DockSTARTer}."
            YesNotice="Stopping and removing ${AppName:-containers, networks, volumes, and images created by DockSTARTer}."
            ComposeCommand[0]="down --remove-orphans ${APPNAME-}"
            ;;
        pull)
            Question="Pull the latest images for ${AppName:-all enabled services}?"
            NoNotice="Not pulling the latest images for ${AppName:-all enabled services}."
            YesNotice="Pulling the latest images for ${AppName:-all enabled services}."
            ComposeCommand[0]="pull --include-deps ${APPNAME-}"
            ;;
        restart)
            Question="Restart ${AppName:-all stopped and running services}?"
            NoNotice="Not restarting ${AppName:-all stopped and running services}."
            YesNotice="Restarting ${AppName:-all stopped and running services}."
            ComposeCommand[0]="restart ${APPNAME-}"
            ;;
        update)
            Question="Update ${AppName:-containers for all enabled services}?"
            NoNotice="Not updating ${AppName:-containers for all enabled services}."
            YesNotice="Updating ${AppName:-containers for all enabled services}."
            CommandNotice[0]="Pulling the latest images for ${AppName:-all enabled services}."
            ComposeCommand[0]="pull --include-deps ${APPNAME-}"
            CommandNotice[1]="Starting ${AppName:-containers for all enabled services}."
            ComposeCommand[1]="up -d --remove-orphans ${APPNAME-}"
            ;;
        up)
            Question="Start ${AppName:-containers for all enabled services}?"
            NoNotice="Not starting ${AppName:-containers for all enabled services}."
            YesNotice="Starting ${AppName:-containers for all enabled services}."
            ComposeCommand[0]="up -d --remove-orphans ${APPNAME-}"
            ;;
        *)
            Question="Update containers for all enabled services?"
            NoNotice="Not updating containers for all enabled services."
            YesNotice="Updating containers for all enabled services."
            CommandNotice[0]="Pulling the latest images for all enabled services."
            ComposeCommand[0]="pull --include-deps"
            CommandNotice[1]="Starting containers for all enabled services."
            ComposeCommand[1]="up -d --remove-orphans"
            ;;
    esac
    if run_script 'question_prompt' Y "${Question}" "${DC["TitleWarning"]}${Title}" "${FORCE:+Y}"; then
        [[ -n ${YesNotice-} ]] && notice "${YesNotice}"
        run_script 'require_docker'
        for index in "${!ComposeCommand[@]}"; do
            [[ -n ${CommandNotice[index]-} ]] && notice "${CommandNotice[index]}"
            eval "docker compose --project-directory ${COMPOSE_FOLDER}/ ${ComposeCommand[index]}" ||
                fatal "Failed to run compose.\nFailing command: ${F[C]}docker compose --project-directory ${COMPOSE_FOLDER}/ ${ComposeCommand[index]}"
        done
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
