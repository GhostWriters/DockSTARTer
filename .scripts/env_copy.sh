#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

env_copy() {
    local FROM_VAR=${1-}
    local TO_VAR=${2-}
    local FROM_VAR_FILE=${3:-$COMPOSE_ENV}
    local TO_VAR_FILE=${4:-$FROM_VAR_FILE}

    if [[ ! -f ${VAR_FILE} ]]; then
        # Source file does not exist, warn and return
        warn "File ${FROM_VAR_FILE} does not exist."
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
        notice "Creating ${TO_VAR_FILE}"
        touch "${TO_VAR_FILE}"
    fi
    if run_script 'env_var_exists' "${TO_VAR}" "${TO_VAR_FILE}"; then
        # Destination variable exists, do nothing
        return
    fi

    if [[ ${FROM_VAR_FILE} == "${TO_VAR_FILE}" ]]; then
        notice "Copying variable in ${FROM_VAR_FILE}:"
        notice "   ${FROM_VAR} to ${TO_VAR}"
    else
        notice "Copying variable:"
        notice "   ${FROM_VAR} [${FROM_VAR_FILE}] to"
        notice "   ${TO_VAR} [${TO_VAR_FILE}]"
    fi
    printf '\n%s\n' "${NEW_VAR_LINE}" >> "${TO_VAR_FILE}" ||
        fatal "Failed to add '${NEW_VAR_LINE}' in ${TO_VAR_FILE}\nFailing command: ${F[C]}printf '\n%s\n' \"${NEW_VAR_LINE}\" >> \"${TO_VAR_FILE}\""
}

test_env_copy() {
    warn "CI does not test env_copy."
}
