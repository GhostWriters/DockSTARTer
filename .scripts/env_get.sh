#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

env_get() {
    # env_get GET_VAR [VAR_FILE]
    # env_get APPNAME:GET_VAR
    #
    # Returns the variable "GET_VAR"  If no "VAR_FILE" is given, uses the global .env file
    # If "APPNAME:" is provided, gets variable from ".env.app.appname"
    local GET_VAR=${1-}
    local VAR_FILE=${2:-$COMPOSE_ENV}

    if ! run_script 'varname_is_valid' "${GET_VAR}"; then
        error "${F[C]}${GET_VAR}${NC} is an invalid variable name."
        return
    fi

    if [[ ${GET_VAR} =~ ^[A-Za-z0-9_]+: ]]; then
        # GET_VAR is in the form of "APPNAME:VARIABLE", set new file to use
        local APPNAME=${GET_VAR%%:*}
        VAR_FILE="$(run_script 'app_env_file' "${APPNAME}")"
        GET_VAR=${GET_VAR#"${APPNAME}:"}
    fi
    if [[ -f ${VAR_FILE} ]]; then
        grep --color=never -Po "^\s*${GET_VAR}\s*=\K.*" "${VAR_FILE}" | tail -1 | xargs || true
    else
        # VAR_FILE does not exist, give a warning
        warn "File '${C["File"]}${VAR_FILE}${NC}' does not exist."
    fi

}

test_env_get() {
    run_script 'appvars_create' WATCHTOWER
    run_script 'env_get' WATCHTOWER__ENABLED
    run_script 'env_get' WATCHTOWER:WATCHTOWER_NOTIFICATIONS
    run_script 'appvars_purge' WATCHTOWER
}
