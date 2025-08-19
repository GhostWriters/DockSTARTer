#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

env_delete() {
    local DELETE_VAR=${1-}
    local VAR_FILE=${2:-$COMPOSE_ENV}

    if [[ ${DELETE_VAR} =~ ^[A-Za-z0-9_]+: ]]; then
        # SET_VAR is in the form of "APPNAME:VARIABLE", set new file to use
        local APPNAME=${DELETE_VAR%%:*}
        VAR_FILE="$(run_script 'app_env_file' "${APPNAME}")"
        DELETE_VAR=${DELETE_VAR#"${APPNAME}:"}
    fi
    if [[ ! -f ${VAR_FILE} ]]; then
        # Variable file does not exist, warn and return
        warn "File '${C["File"]}${VAR_FILE}${NC}' does not exist."
        return
    fi
    if ! grep -q -P "^\s*\K${DELETE_VAR}(?=\s*=)" "${VAR_FILE}"; then
        # Variable to delete does not exists, do nothing
        return
    fi

    notice "Removing variables from ${C["File"]}${VAR_FILE}${NC}:"
    notice "   ${C["Var"]}${DELETE_VAR}${NC}"
    sed -i "/^\s*${DELETE_VAR}\s*=/d" "${VAR_FILE}" ||
        fatal "Failed to remove var '${C["Var"]}${DELETE_VAR}${NC}' in '${C["File"]}${VAR_FILE}${NC}'\nFailing command: ${C["FailingCommand"]}sed -i \"/^\\s*${DELETE_VAR}\\s*=/d\" \"${VAR_FILE}\""
}

test_env_delete() {
    # run_script 'env_delete'
    warn "CI does not test env_delete."
}
