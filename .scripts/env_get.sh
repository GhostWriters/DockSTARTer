#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

env_get() {
    # env_get GET_VAR [VAR_FILE]
    # env_get APPNAME:GET_VAR
    #
    # Returns the variable "GET_VAR"  If no "VAR_FILE" is given, uses the global .env file
    # If "APPNAME:" is provided, gets variable from "env_files/appname.env"
    #
    # Function will also return success/fail in the return value based on if the variable exists

    local GET_VAR=${1-}
    local VAR_FILE=${2:-$COMPOSE_ENV}
    if [[ ${GET_VAR} =~ ^[A-Za-z0-9_]+: ]]; then
        # GET_VAR is in the form of "APPNAME:VARIABLE", set new file to use
        local APPNAME=${GET_VAR%%:*}
        VAR_FILE="${APP_ENV_FOLDER}/${APPNAME,,}.env"
        GET_VAR=${GET_VAR#"${APPNAME}:"}
    fi
    if [[ -f ${VAR_FILE} ]]; then
        grep --color=never -Po "^\s*${GET_VAR}\s*=\K.*" "${VAR_FILE}" | tail -1 | xargs
        return ${PIPESTATUS[0]}
    else
        # VAR_FILE does not exist, give a warning
        warn "${VAR_FILE} does not exist."
        return 1
    fi

}

test_env_get() {
    run_script 'appvars_create' WATCHTOWER
    run_script 'env_get' WATCHTOWER__ENABLED
    notice "'env_get' WATCHTOWER returned $?"
    run_script 'env_get' WATCHTOWER:WATCHTOWER_NOTIFICATIONS
    notice "'env_get' WATCHTOWER:WATCHTOWER_NOTIFICATIONS returned $?"
    run_script 'env_get' VARTHATDOESNOTEXIST
    notice "'env_get' VARTHATDOESNOTEXIST returned $?"
    run_script 'appvars_purge' WATCHTOWER
}
