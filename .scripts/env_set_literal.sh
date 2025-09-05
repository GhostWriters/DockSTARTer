#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

env_set_literal() {
    # env_set_literal SET_VAR NEW_VAL [VAR_FILE]
    # env_set_literal APPNAME:SET_VAR NEW_VAL
    #
    # Sets the variable "SET_VAR"  If no "VAR_FILE" is given, uses the global .env file
    # If "APPNAME:" is provided, gets variable from ".env.app.appname"


    local SET_VAR=${1-}
    local NEW_VAL_B64
    set +u # suppress possible "parameter not set" errors when reading lines from the .env files
    NEW_VAL_B64="$(base64 -w0 <<< "${2-}")"
    set -u
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
    if [[ ! -f ${VAR_FILE} ]]; then
        # VAR_FILE does not exist, create it
        mkdir -p "${VAR_FILE%/*}" && touch "${VAR_FILE}"
    fi
    sed -i "/^\s*${SET_VAR}\s*=/d" "${VAR_FILE}" || true
    printf '\n%s' "${SET_VAR}=" >> "${VAR_FILE}" ||
        fatal "Failed to set ${C["Var"]}${SET_VAR}=${NEW_VAL}${NC}\nFailing command: ${C["FailingCommand"]} printf '\n%s' \"${SET_VAR}=\" >> \"${VAR_FILE}\""
    base64 -d <<< "${NEW_VAL_B64}" >> "${VAR_FILE}" ||
        fatal "Failed to set ${C["Var"]}${SET_VAR}=${NEW_VAL}${NC}\nFailing command: ${C["FailingCommand"]} base64 -d <<< \"${NEW_VAL_B64}\" >> \"${VAR_FILE}\""
}

test_env_set_literal() {
    run_script 'appvars_create' WATCHTOWER
    run_script 'env_set_literal' WATCHTOWER__ENABLED false
    run_script 'env_set_literal' WATCHTOWER:WATCHTOWER_NOTIFICATIONS newvalue
    run_script 'env_get_literal' WATCHTOWER__ENABLED
    run_script 'env_get_literal' WATCHTOWER:WATCHTOWER_NOTIFICATIONS
    run_script 'appvars_purge' WATCHTOWER
}
