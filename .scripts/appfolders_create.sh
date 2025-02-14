#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

appfolders_create() {
    local APPNAME=${1-}
    APPNAME=${APPNAME^^}

    local FILENAME=${APPNAME,,}
    local APP_FOLDER="${TEMPLATES_FOLDER}/${FILENAME}"
    local APP_FOLDERS_FILE="${APP_FOLDER}/${FILENAME}.folders"

    if [[ -f ${APP_FOLDERS_FILE} ]]; then
        local -a FOLDERS_ARRAY=()
        readarray -t FOLDERS_ARRAY < <(grep -o -P '^\s*\K.*(?=\s*)$' "${APP_FOLDERS_FILE}" | grep -v '^$' || true)
        if [[ -n ${FOLDERS_ARRAY[@]-} ]]; then
            notice "Creating config folders for ${APPNAME}."
            local DOCKER_VOLUME_CONFIG
            DOCKER_VOLUME_CONFIG=$(run_script 'env_get' DOCKER_VOLUME_CONFIG)
            for FOLDER in "${FOLDERS_ARRAY[@]-}"; do
                local ACTUAL_FOLDER
                ACTUAL_FOLDER=$(echo "$FOLDER" | DOCKER_VOLUME_CONFIG="${DOCKER_VOLUME_CONFIG}" envsubst)
                if [[ ! -d ${ACTUAL_FOLDER} ]]; then
                    notice "Creating folder ${ACTUAL_FOLDER}"
                    mkdir -p "${ACTUAL_FOLDER}" | warn "Could not create folder ${ACTUAL_FOLDER}"
                fi
            done
        fi
    fi
}

test_appfolders_create() {
    warn "CI does not test appfolers_create."
}
