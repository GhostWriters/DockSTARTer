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
        local -a FoldersArray=()
        readarray -t FoldersArray < <(${GREP} -o -P '^\s*\K.*(?=\s*)$' "${APP_FOLDERS_FILE}" | ${GREP} -v '^$' || true)
        if [[ -n ${FoldersArray[*]-} ]]; then
            for index in "${!FoldersArray[@]}"; do
                local Folder
                FoldersArray[index]="$(
                    run_script 'expand_vars_using_varfile' "${FoldersArray[$index]}"
                )"
                if [[ -z ${FoldersArray[$index]} || -d ${FoldersArray[$index]} ]]; then
                    unset 'FoldersArray[index]'
                fi
            done
            if [[ -n ${FoldersArray[*]-} ]]; then
                notice "Creating config folders for '${C["App"]-}${AppName}${NC-}'."
                for Folder in "${FoldersArray[@]-}"; do
                    notice "Creating folder '${C["Folder"]-}${Folder}${NC-}'"
                    mkdir -p "${Folder}" ||
                        warn \
                            "Could not create folder '${C["Folder"]-}${Folder}${NC-}'" \
                            "Failing command: ${C["FailingCommand"]-}mkdir -p  \"${Folder}\""
                    if [[ -d ${Folder} ]]; then
                        run_script 'set_permissions' "${Folder}"
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
