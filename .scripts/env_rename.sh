#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

env_rename() {
    local FROM_VAR=${1-}
    local TO_VAR=${2-}
    local FROM_VAR_FILE=${3:-$COMPOSE_ENV}
    local TO_VAR_FILE=${4:-$FROM_VAR_FILE}

    if [[ ! -f ${FROM_VAR_FILE} ]]; then
        # Source file does not exist, warn and return
        warn "File '${C["File"]}${FROM_VAR_FILE}${NC}' does not exist."
        return
    fi
    if [[ ${FROM_VAR_FILE} == "${TO_VAR_FILE}" && ${FROM_VAR} == "${TO_VAR}" ]]; then
        # Trying to move to the same name in the same file, do nothing
        return
    fi

    local NEW_VAR_LINE
    NEW_VAR_LINE="$(sed -n "s/^\s*${FROM_VAR}\s*=/${TO_VAR}=/gp" "${FROM_VAR_FILE}" | tail -1)"
    if [[ -z ${NEW_VAR_LINE} ]]; then
        # Source variable does not exist, do nothing
        return
    fi
    if [[ ! -f ${TO_VAR_FILE} ]]; then
        # Destination file does not exist, create it
        notice "Creating '${C["File"]}${TO_VAR_FILE}${NC}'"
        touch "${TO_VAR_FILE}"
    fi
    if run_script 'env_var_exists' "${TO_VAR}" "${TO_VAR_FILE}"; then
        # Destination variable exists, do nothing
        return
    fi

    if [[ ${FROM_VAR_FILE} == "${TO_VAR_FILE}" ]]; then
        notice "Renaming variable in ${C["File"]}${FROM_VAR_FILE}${NC}:"
        notice "   ${C["Var"]}${FROM_VAR}${NC} to ${C["Var"]}${TO_VAR}${NC}"
    else
        notice "Moving variable:"
        notice "   ${C["Var"]}${FROM_VAR}${NC} [${C["File"]}${FROM_VAR_FILE}${NC}] to"
        notice "   ${C["Var"]}${TO_VAR}${NC} [${C["File"]}${TO_VAR_FILE}${NC}]"
    fi
    printf '\n%s\n' "${NEW_VAR_LINE}" >> "${TO_VAR_FILE}" ||
        fatal "Failed to add '${C["Var"]}${NEW_VAR_LINE}${NC}' in '${C["File"]}${TO_VAR_FILE}${NC}'\nFailing command: ${C["FailingCommand"]}printf '\n%s\n' \"${NEW_VAR_LINE}\" >> \"${TO_VAR_FILE}\""
    sed -i "/^\s*${FROM_VAR}\s*=/d" "${FROM_VAR_FILE}" ||
        fatal "Failed to remove var '${C["Var"]}${FROM_VAR}${NC}' in '${C["File"]}${FROM_VAR_FILE}${NC}'\nFailing command: ${C["FailingCommand"]}sed -i \"/^\\s*${FROM_VAR}\\s*=/d\" \"${FROM_VAR_FILE}\""
    declare -gx PROCESS_APPVARS_CREATE_ALL=1
    declare -gx PROCESS_ENV_UPDATE=1
    declare -gx PROCESS_YML_MERGE=1
}

test_env_rename() {
    # run_script 'env_rename'
    warn "CI does not test env_rename."
}
