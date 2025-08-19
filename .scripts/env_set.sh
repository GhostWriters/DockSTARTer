#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

env_set() {
    # env_set SET_VAR NEW_VAL [VAR_FILE]
    # env_set APPNAME:SET_VAR NEW_VAL
    #
    # Returns the variable "GET_VAR"  If no "VAR_FILE" is given, uses the global .env file
    # If "APPNAME:" is provided, gets variable from ".env.app.appname"
    local SET_VAR=${1-}
    local NEW_VAL=${2-}
    local VAR_FILE=${3:-$COMPOSE_ENV}

    if ! run_script 'varname_is_valid' "${SET_VAR}"; then
        error "${F[C]}${SET_VAR}${NC} is an invalid variable name."
        return
    fi

    if [[ ${SET_VAR} =~ ^[A-Za-z0-9_]+: ]]; then
        # SET_VAR is in the form of "APPNAME:VARIABLE", set new file to use
        local APPNAME=${SET_VAR%%:*}
        VAR_FILE="$(run_script 'app_env_file' "${APPNAME}")"
        SET_VAR=${SET_VAR#"${APPNAME}:"}
    fi

    # https://unix.stackexchange.com/questions/422165/escape-double-quotes-in-variable/422170#422170
    NEW_VAL="$(printf "%s\n" "${NEW_VAL-}" | sed -e "s/'/'\"'\"'/g" -e "1s/^/'/" -e "\$s/\$/'/")"

    if [[ ! -f ${VAR_FILE} ]]; then
        # VAR_FILE does not exist, create it
        mkdir -p "${VAR_FILE%/*}" && touch "${VAR_FILE}"
    fi
    sed -i "/^\s*${SET_VAR}\s*=/d" "${VAR_FILE}" || true
    echo "${SET_VAR}=${NEW_VAL}" >> "${VAR_FILE}" || fatal "Failed to set ${C["Var"]}${SET_VAR}=${NEW_VAL}${NC}\nFailing command: ${C["FailingCommand"]} echo \"${SET_VAR}=${NEW_VAL}\" >> \"${VAR_FILE}\""
    declare -gx PROCESS_APPVARS_CREATE_ALL=1
    declare -gx PROCESS_ENV_UPDATE=1
    declare -gx PROCESS_YML_MERGE=1
}

test_env_set() {
    run_script 'appvars_create' WATCHTOWER
    run_script 'env_set' WATCHTOWER__ENABLED false
    run_script 'env_set' WATCHTOWER:WATCHTOWER_NOTIFICATIONS newvalue
    run_script 'env_get' WATCHTOWER__ENABLED
    run_script 'env_get' WATCHTOWER:WATCHTOWER_NOTIFICATIONS
    run_script 'appvars_purge' WATCHTOWER
}
