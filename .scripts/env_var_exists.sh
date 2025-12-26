#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=(
    grep
)

env_var_exists() {
    # env_var_exists VAR_NAME [VAR_FILE]
    # env_var_exists APPNAME:VAR_NAME
    #
    # Returns if the variable "VAR_NAME" exists. If no "VAR_FILE" is given, uses the global .env file
    # If "APPNAME:" is provided, gets variable from ".env.app.appname"

    local VAR_NAME=${1-}
    local VAR_FILE=${2:-$COMPOSE_ENV}
    if [[ ${VAR_NAME} =~ ^[A-Za-z0-9_]+: ]]; then
        # VAR_NAME is in the form of "APPNAME:VARIABLE", set new file to use
        local APPNAME=${VAR_NAME%%:*}
        VAR_FILE="$(run_script 'app_env_file' "${APPNAME}")"
        VAR_NAME=${VAR_NAME#"${APPNAME}:"}
    fi
    if [[ -f ${VAR_FILE} ]]; then
        ${GREP} --color=never -q -P "^\s*${VAR_NAME}\s*=\K.*" "${VAR_FILE}"
        return $?
    else
        # VAR_FILE does not exist, give a warning
        warn "${C["File"]}${VAR_FILE}${NC} does not exist."
        return 1
    fi

}

test_env_var_exists() {
    run_script 'appvars_create' WATCHTOWER
    run_script 'env_var_exists' WATCHTOWER__ENABLED
    notice "'env_var_exists' WATCHTOWER returned $?"
    run_script 'env_var_exists' WATCHTOWER:WATCHTOWER_NOTIFICATIONS
    notice "'env_var_exists' WATCHTOWER:WATCHTOWER_NOTIFICATIONS returned $?"
    run_script 'env_var_exists' VARTHATDOESNOTEXIST
    notice "'env_var_exists' VARTHATDOESNOTEXIST returned $?"
    run_script 'env_var_exists' APPTHATDOESNOTEXIST:WATCHTOWER
    notice "'env_var_exists' APPTHATDOESNOTEXIST:WATCHTOWER returned $?"
    run_script 'appvars_purge' WATCHTOWER
}
