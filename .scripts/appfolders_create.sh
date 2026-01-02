#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=(
    grep
)

appfolders_create() {
    local -u APPNAME=${1-}
    local -l appname=${APPNAME}
    local AppName
    AppName="$(run_script 'app_nicename' "${APPNAME}")"

    local APP_FOLDERS_FILE
    APP_FOLDERS_FILE="$(run_script 'app_instance_file' "${appname}" "*.folders")"

    if [[ -f ${APP_FOLDERS_FILE} ]]; then
        local -a FOLDERS_ARRAY=()
        readarray -t FOLDERS_ARRAY < <(${GREP} -o -P '^\s*\K.*(?=\s*)$' "${APP_FOLDERS_FILE}" | ${GREP} -v '^$' || true)
        if [[ -n ${FOLDERS_ARRAY[*]-} ]]; then
            local HOME DOCKER_CONFIG_FOLDER DOCKER_VOLUME_CONFIG
            HOME="$(run_script 'env_get' HOME)"
            DOCKER_CONFIG_FOLDER="$(run_script 'env_get' DOCKER_CONFIG_FOLDER)"
            DOCKER_VOLUME_CONFIG="$(run_script 'env_get' DOCKER_VOLUME_CONFIG)"
            DOCKER_CONFIG_FOLDER="$(
                echo "${DOCKER_CONFIG_FOLDER}" | \
                    HOME="${HOME}" XDG_CONFIG_HOME="${XDG_CONFIG_HOME}" \
                    envsubst
            )"
            DOCKER_VOLUME_CONFIG="$(
                echo "${DOCKER_VOLUME_CONFIG}" | \
                    HOME="${HOME}" XDG_CONFIG_HOME="${XDG_CONFIG_HOME}" DOCKER_CONFIG_FOLDER="${DOCKER_CONFIG_FOLDER-}" \
                    envsubst
            )"
            for index in "${!FOLDERS_ARRAY[@]}"; do
                local FOLDER
                FOLDERS_ARRAY[index]="$(
                    echo "${FOLDERS_ARRAY[$index]}" | \
                        HOME="${HOME}" \
                        XDG_CONFIG_HOME="${XDG_CONFIG_HOME}" \
                        DOCKER_CONFIG_FOLDER="${CONFIG_FOLDER-}" \
                        DOCKER_VOLUME_CONFIG="${DOCKER_VOLUME_CONFIG-}" \
                        envsubst
                )"
                if [[ -z ${FOLDERS_ARRAY[$index]} || -d ${FOLDERS_ARRAY[$index]} ]]; then
                    unset 'FOLDERS_ARRAY[index]'
                fi
            done
            if [[ -n ${FOLDERS_ARRAY[*]-} ]]; then
                notice "Creating config folders for '${C["App"]}${AppName}${NC}'."
                for FOLDER in "${FOLDERS_ARRAY[@]-}"; do
                    notice "Creating folder '${C["Folder"]}${FOLDER}${NC}'"
                    mkdir -p "${FOLDER}" ||
                        warn \
                            "Could not create folder '${C["Folder"]}${FOLDER}${NC}'" \
                            "Failing command: ${C["FailingCommand"]}mkdir -p  \"${FOLDER}\""
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
