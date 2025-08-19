#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

appfolders_create() {
    local -u APPNAME=${1-}
    local -l appname=${APPNAME}
    local AppName
    AppName="$(run_script 'app_nicename' "${APPNAME}")"

    local APP_FOLDERS_FILE
    APP_FOLDERS_FILE="$(run_script 'app_instance_file' "${appname}" "*.folders")"

    if [[ -f ${APP_FOLDERS_FILE} ]]; then
        local -a FOLDERS_ARRAY=()
        readarray -t FOLDERS_ARRAY < <(grep -o -P '^\s*\K.*(?=\s*)$' "${APP_FOLDERS_FILE}" | grep -v '^$' || true)
        if [[ -n ${FOLDERS_ARRAY[*]-} ]]; then
            local DOCKER_VOLUME_CONFIG
            DOCKER_VOLUME_CONFIG="$(run_script 'env_get' DOCKER_VOLUME_CONFIG)"
            for index in "${!FOLDERS_ARRAY[@]}"; do
                local FOLDER
                FOLDERS_ARRAY[index]="$(echo "${FOLDERS_ARRAY[$index]}" | DOCKER_VOLUME_CONFIG="${DOCKER_VOLUME_CONFIG-}" envsubst)"
                if [[ -z ${FOLDERS_ARRAY[$index]} || -d ${FOLDERS_ARRAY[$index]} ]]; then
                    unset 'FOLDERS_ARRAY[index]'
                fi
            done
            if [[ -n ${FOLDERS_ARRAY[*]-} ]]; then
                notice "Creating config folders for '${C["App"]}${AppName}${NC}'."
                for FOLDER in "${FOLDERS_ARRAY[@]-}"; do
                    notice "Creating folder '${C["Folder"]}${FOLDER}${NC}'"
                    mkdir -p "${FOLDER}" || warn "Could not create folder '${C["Folder"]}${FOLDER}${NC}'"
                    if [[ -d ${FOLDER} ]]; then
                        run_script 'set_permissions' "${FOLDER}"
                    fi
                done
            fi
        fi
    fi
}

test_appfolders_create() {
    run_script 'appfolders_create' WATCHTOWER
    run_script 'appfolders_create' AUDIOBOOKSHELF
    run_script 'appfolders_create' APPTHATDOESNOTEXIST
    #warn "CI does not test appfolers_create."
}
