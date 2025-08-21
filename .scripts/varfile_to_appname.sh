#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

varfile_to_appname() {
    # Returns the DS application name based on the variable filename passed

    local VarFile=${1-}
    local FileName
    FileName="$(basename "${VarFile}")"
    local Prefix='.env.app.'
    local AppName="${FileName#"${Prefix}"}"
    if [[ ${AppName} != "${FileName}" && ${AppName} == "${AppName,,}" ]] && run_script 'appname_is_valid' "${AppName}"; then
        echo "${AppName}"
    fi
}

test_varfile_to_appname() {
    local -a PathList=(
        '/home/test/.docker/.env'
        '/home/test/.docker/.env.app.radarr'
        '/home/test/.docker/.env.app.Radarr'
        '/home/test/.docker/.env.app.1radarr'
        '/home/test/.docker/.env.app.radarr__4k'
        '/home/test/.docker/.env.app.radarr___4k'
    )
    for filepath in "${PathList[@]}"; do
        notice "[${filepath}] [$(run_script 'varfile_to_appname' "${filepath}")]"
    done
}
