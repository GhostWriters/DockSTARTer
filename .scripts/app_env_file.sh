#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_env_file() {
    local AppName=${1:-}

    echo "${APP_ENV_FOLDER}/${AppName,,}.env"
}

test_app_env_file() {
    for AppName in watchtower radarr radarr__4k; do
            notice "[${AppName}] [$(run_script 'app_env_file' "${AppName}")]"
    done
}
