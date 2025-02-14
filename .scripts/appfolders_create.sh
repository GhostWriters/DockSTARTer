#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

appfolders_create() {
    local APPNAME=${1-}
    APPNAME=${APPNAME^^}

    local FILENAME=${APPNAME,,}
    local APP_FOLDER="${TEMPLATES_FOLDER}/${FILENAME}"
    local APP_FOLDERS_FILE="${APP_FOLDER}/${FILENAME}.folders"

    notice "APPNAME [${APPNAME}]"
    notice "APP_FOLDER [${APP_FOLDER}]"
    notice "APP_FOLDERS_FILE [${APP_FOLDERS_FILE}]"
    if [[ -f ${APP_FOLDERS_FILE} ]]; then
        notice "Creating config folders for ${APPNAME}."
        local -a APP_FOLDERS_ARRAY=()
        readarray -t APP_FOLDERS_ARRAY < <(grep -o -P '^\s*\K.*(?=\s*)$' "${APP_FOLDERS_FILE}" | grep -v '^$' || true)
        if [[ -n ${APP_FOLDERS_ARRAY[@]-} ]]; then
            notice "APP_FOLDERS_ARRAY [${APP_FOLDERS_ARRAY[@]-}]"
            local DOCKER_VOLUME_CONFIG
            DOCKER_VOLUME_CONFIG=$(run_script 'env_get' DOCKER_VOLUME_CONFIG)
            notice "DOCKER_VOLUME_CONFIG [${DOCKER_VOLUME_CONFIG}]"
            for FOLDER in "${APP_FOLDERS_ARRAY[@]-}"; do
                local ACTUAL_FOLDER
                notice "FOLDER [${FOLDER}]"
                ACTUAL_FOLDER=$(echo "$FOLDER" | DOCKER_VOLUME_CONFIG="${DOCKER_VOLUME_CONFIG}" envsubst)
                notice "ACTUAL_FOLDER [${ACTUAL_FOLDER}]"
            done
        fi
    fi
}

test_appfolders_create() {
    warn "CI does not test appfolers_create."
}
