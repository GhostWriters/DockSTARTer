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
                NoNotice="Not stopping and removing: ${C["App"]}${AppName}${NC}."
                YesNotice="Stopping and removing ${C["App"]}${AppName}${NC}."
            else
                Question="Stop and remove containers, networks, volumes, and images created by ${APPLICATION_NAME}?"
                NoNotice="Not stopping and removing containers, networks, volumes, and images created by ${APPLICATION_NAME}."
                YesNotice="Stopping and removing containers, networks, volumes, and images created by ${APPLICATION_NAME}."
            fi
            ComposeCommand[0]="down --remove-orphans ${APPNAME-}"
            ;;
        pull)
            if [[ -n ${AppName-} ]]; then
                Question="Pull the latest images for: ${AppName}?"
                NoNotice="Not pulling the latest images for: ${C["App"]}${AppName}${NC}."
                YesNotice="Pulling the latest images for: ${C["App"]}${AppName}${NC}."
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
                NoNotice="Not restarting: ${C["App"]}${AppName}${NC}."
                YesNotice="Restarting: ${C["App"]}${AppName}${NC}."
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
                NoNotice="Not stopping: ${C["App"]}${AppName}${NC}."
                YesNotice="Stopping: ${C["App"]}${AppName}${NC}."
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
                NoNotice="Not updating and starting: ${C["App"]}${AppName}${NC}."
                YesNotice="Updating and starting: ${C["App"]}${AppName}${NC}."
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
                NoNotice="Not starting: ${C["App"]}${AppName}${NC}."
                YesNotice="Starting: ${C["App"]}${AppName}${NC}."
            else
                Question="Start containers for all enabled services?"
                NoNotice="Not starting containers for all enabled services."
                YesNotice="Starting containers for all enabled services."
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

    local -i result=0
    if run_script 'question_prompt' Y "${Question}" "${Title}" "${FORCE:+Y}"; then
        if use_dialog_box; then
            coproc {
                dialog_pipe "${DC[TitleSuccess]}${Title}" "${YesNotice}${DC[NC]}\n${DC[CommandLine]} ${APPLICATION_COMMAND} --compose ${ComposeInput}"
            }
            local -i DialogBox_PID=${COPROC_PID}
            local -i DialogBox_FD="${COPROC[1]}"
            {
                [[ -n ${YesNotice-} ]] && notice "${YesNotice}"
                run_script 'require_docker'
                if run_script 'yml_merge'; then
                    for index in "${!ComposeCommand[@]}"; do
                        local Command="docker compose --project-directory ${COMPOSE_FOLDER}/ ${ComposeCommand[index]}"
                        notice "Running: ${C["RunningCommand"]}${Command}${NC}"
                        eval "${Command}" || result=$?
                        if [[ ${result} != 0 ]]; then
                            error "Failed to run compose.\nFailing command: ${C["FailingCommand"]}${Command}"
                            break
                        fi
                    done
                else
                    result=1
                fi
            } >&${DialogBox_FD} 2>&1
            exec {DialogBox_FD}<&-
            wait ${DialogBox_PID}
        else
            [[ -n ${YesNotice-} ]] && notice "${YesNotice}"
            run_script 'require_docker'
            if run_script 'yml_merge'; then
                for index in "${!ComposeCommand[@]}"; do
                    local Command="docker compose --project-directory ${COMPOSE_FOLDER}/ ${ComposeCommand[index]}"
                    notice "Running: ${C["RunningCommand"]}${Command}${NC}"
                    eval "${Command}" || result=$?
                    if [[ ${result} != 0 ]]; then
                        error "Failed to run compose.\nFailing command: ${C["FailingCommand"]}${Command}"
                        break
                    fi
                done
            else
                result=1
            fi
        fi
    else
        if use_dialog_box; then
            [[ -n ${NoNotice-} ]] && notice "${NoNotice}" |& dialog_pipe "${DC[TitleError]}${Title}" "${NoNotice}"
        else
            [[ -n ${NoNotice-} ]] && notice "${NoNotice}"
        fi
    fi
    return ${result}
}

test_docker_compose() {
    run_script 'appvars_create' WATCHTOWER
    cat "${COMPOSE_ENV}"
    run_script 'yml_merge'
    eval "docker compose --project-directory ${COMPOSE_FOLDER}/ config" || fatal "Failed to display compose config.\nFailing command: ${C["FailingCommand"]}docker compose --project-directory ${COMPOSE_FOLDER}/ config"
    run_script 'docker_compose'
}
