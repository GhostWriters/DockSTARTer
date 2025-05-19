#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_env_file() {
    local AppName=${1:-}

    if [[ ! -d ${APP_ENV_FOLDER} ]]; then
        warn "Folder ${APP_ENV_FOLDER} not found. Creating it."
        mkdir -p "${APP_ENV_FOLDER}" ||
            fatal "Failed to create folder.\nFailing command: ${F[C]}mkdir -p \"${APP_ENV_FOLDER}\""
    fi
    echo "${APP_ENV_FOLDER}/${AppName,,}.env"
}

test_app_env_file() {
    for AppName in watchtower radarr radarr__4k; do
        notice "[${AppName}] [$(run_script 'app_env_file' "${AppName}")]"
    done
}
