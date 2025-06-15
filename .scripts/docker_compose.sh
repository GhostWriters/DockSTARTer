#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

docker_compose() {
    local ComposeInput=${1-}
    local Command=${ComposeInput%% *}
    local APPNAME AppName
    if [[ ${ComposeInput} == *" "* ]]; then
        APPNAME=${ComposeInput#* }
        AppName="$(run_script 'app_nicename' "${APPNAME}" | xargs)"
        AppName="${AppName// /, }"
    fi

    local Title="Docker Compose"

    local Question YesNotice NoNotice
    local -a ComposeCommand
    case ${Command} in
        merge | generate)
            Question="Merge enabled app templates to docker-compose.yml?"
            NoNotice="Not merging enabled app templates to docker-compose.yml."
            YesNotice="Merging enabled app templates to docker-compose.yml."
            ;;
        down)
            if [[ -n ${AppName-} ]]; then
                Question="Stop and remove: ${AppName}?"
                NoNotice="Not stopping and removing: ${AppName}."
                YesNotice="Stopping and removing ${AppName}."
            else
                Question="Stop and remove containers, networks, volumes, and images created by DockSTARTer?"
                NoNotice="Not stopping and removing containers, networks, volumes, and images created by DockSTARTer."
                YesNotice="Stopping and removing containers, networks, volumes, and images created by DockSTARTer."
            fi
            ComposeCommand[0]="down --remove-orphans ${APPNAME-}"
            ;;
        pull)
            if [[ -n ${AppName-} ]]; then
                Question="Pull the latest images for: ${AppName}?"
                NoNotice="Not pulling the latest images for: ${AppName}."
                YesNotice="Pulling the latest images for: ${AppName}."
            else
                Question="Pull the latest images for all enabled services?"
                NoNotice="Not pulling the latest images for all enabled services."
                YesNotice="Pulling the latest images for all enabled services."
            fi
            ComposeCommand[0]="pull --include-deps ${APPNAME-}"
            ;;
        restart)
            if [[ -n ${AppName-} ]]; then
                Question="Restart: ${AppName}?"
                NoNotice="Not restarting: ${AppName}."
                YesNotice="Restarting: ${AppName}."
            else
                Question="Restart all stopped and running containers?"
                NoNotice="Not restarting all stopped and running containers."
                YesNotice="Restarting all stopped and running containers."
            fi
            ComposeCommand[0]="restart ${APPNAME-}"
            ;;
        stop)
            if [[ -n ${AppName-} ]]; then
                Question="Stop: ${AppName}?"
                NoNotice="Not stopping: ${AppName}."
                YesNotice="Stopping: ${AppName}."
            else
                Question="Stop all running services?"
                NoNotice="Not stopping all running services."
                YesNotice="Stopping all running services."
            fi
            ComposeCommand[0]="stop ${APPNAME-}"
            ;;
        update)
            if [[ -n ${AppName-} ]]; then
                Question="Update and start: ${AppName}?"
                NoNotice="Not updating and starting: ${AppName}."
                YesNotice="Updating and starting: ${AppName}."
            else
                Question="Update and start containers for all enabled services?"
                NoNotice="Not updating and starting containers for all enabled services."
                YesNotice="Updating and starting containers for all enabled services."
            fi
            ComposeCommand[0]="pull --include-deps ${APPNAME-}"
            ComposeCommand[1]="up -d --remove-orphans ${APPNAME-}"
            ;;
        up)
            if [[ -n ${AppName-} ]]; then
                Question="Start: ${AppName}?"
                NoNotice="Not starting: ${AppName}."
                YesNotice="Starting: ${AppName}."
            else
                Question="Start ${AppName:-containers for all enabled services}?"
                NoNotice="Not starting ${AppName:-containers for all enabled services}."
                YesNotice="Starting ${AppName:-containers for all enabled services}."
            fi
            ComposeCommand[0]="up -d --remove-orphans ${APPNAME-}"
            ;;
        *)
            Question="Update containers for all enabled services?"
            NoNotice="Not updating containers for all enabled services."
            YesNotice="Updating containers for all enabled services."
            ComposeCommand[0]="pull --include-deps"
            ComposeCommand[1]="up -d --remove-orphans"
            ;;
    esac
    if run_script 'question_prompt' Y "${Question}" "${Title}" "${FORCE:+Y}"; then
        if use_dialog_box; then
            {
                [[ -n ${YesNotice-} ]] && notice "${YesNotice}"
                run_script 'require_docker'
                run_script 'yml_merge'
                for index in "${!ComposeCommand[@]}"; do
                    notice "Running docker compose ${ComposeCommand[index]}"
                    eval "docker compose --project-directory ${COMPOSE_FOLDER}/ ${ComposeCommand[index]}" ||
                        fatal "Failed to run compose.\nFailing command: ${F[C]}docker compose --project-directory ${COMPOSE_FOLDER}/ ${ComposeCommand[index]}"
                done
            } |& dialog_pipe "${DC[TitleSuccess]}${Title}" "${YesNotice}${DC[NC]}\n${DC[CommandLine]} ds --compose ${ComposeInput}"
        else
            [[ -n ${YesNotice-} ]] && notice "${YesNotice}"
            run_script 'require_docker'
            run_script 'yml_merge'
            for index in "${!ComposeCommand[@]}"; do
                notice "Running docker compose ${ComposeCommand[index]}"
                eval "docker compose --project-directory ${COMPOSE_FOLDER}/ ${ComposeCommand[index]}" ||
                    fatal "Failed to run compose.\nFailing command: ${F[C]}docker compose --project-directory ${COMPOSE_FOLDER}/ ${ComposeCommand[index]}"
            done
        fi
    else
        if use_dialog_box; then
            [[ -n ${NoNotice-} ]] && notice "${NoNotice}" |& dialog_pipe "${DC[TitleError]}${Title}"  "${NoNotice}"
        else
            [[ -n ${NoNotice-} ]] && notice "${NoNotice}"
        fi
    fi
}

test_docker_compose() {
    run_script 'appvars_create' WATCHTOWER
    cat "${COMPOSE_ENV}"
    run_script 'yml_merge'
    eval "docker compose --project-directory ${COMPOSE_FOLDER}/ config" || fatal "Failed to display compose config.\nFailing command: ${F[C]}docker compose --project-directory ${COMPOSE_FOLDER}/ config"
    run_script 'docker_compose'
}
