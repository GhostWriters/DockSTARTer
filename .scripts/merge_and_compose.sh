#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

merge_and_compose() {
    Title="Merge and run Docker Compose"
    if use_dialog_box; then
        commands_merge_and_compose "$@" |& dialog_pipe "${Title}" "$@"
    else
        commands_merge_and_compose "$@"
    fi
}

commands_merge_and_compose() {
    run_script 'yml_merge'
    run_script 'docker_compose' "$@"
}

test_merge_and_compose() {
    run_script 'appvars_create' WATCHTOWER
    cat "${COMPOSE_ENV}"
    run_script 'merge_and_compose'
    eval "docker compose --project-directory ${COMPOSE_FOLDER}/ config" || fatal "Failed to display compose config.\nFailing command: ${C["FailingCommand"]}docker compose --project-directory ${COMPOSE_FOLDER}/ config"
    run_script 'appvars_purge' WATCHTOWER
}
