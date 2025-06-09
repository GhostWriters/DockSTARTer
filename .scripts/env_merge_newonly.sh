#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

env_merge_newonly() {
    # env_merge_newonly "MERGE_TO_FILE" "MERGE_FROM_FILE"
    #
    # Merges all new variables from "MERGE_FROM_FILE" to "MERGE_TO_FILE".
    # Skips all variables that already exist in "MERGE_TO_FILE"
    local MERGE_TO_FILE=${1-}
    local MERGE_FROM_FILE=${2-}

    # If "MERGE_TO_FILE" doesn't exists, create it
    if [[ ! -f ${MERGE_TO_FILE} ]]; then
        touch "${MERGE_TO_FILE}"
    fi

    # If "MERGE_FROM_FILE" doesn't exists, give a warning
    if [[ ! -f ${MERGE_FROM_FILE} ]]; then
        warn "File ${MERGE_FROM_FILE} does not exist."
    else
        local MERGE_FROM_LINES=()
        # Read all variable lines into an array, stripping whitespace before and after the variable name
        readarray -t MERGE_FROM_LINES < <(sed -n -E "s/^\s*(\w+)\s*=/\1=/p" "${MERGE_FROM_FILE}" || true)
        if [[ -n ${MERGE_FROM_LINES[*]-} ]]; then
            for index in "${!MERGE_FROM_LINES[@]}"; do
                local line=${MERGE_FROM_LINES[$index]}
                local VARNAME="${line%%=*}"
                if grep -q -P "^\s*${VARNAME}\s*=\K.*" "${MERGE_TO_FILE}"; then
                    # Variable is already in file, skip it
                    unset 'MERGE_FROM_LINES[index]'
                fi
            done
        fi
        if [[ -n ${MERGE_FROM_LINES[*]-} ]]; then
            notice "Adding variables to ${MERGE_TO_FILE}:"
            for line in "${MERGE_FROM_LINES[@]}"; do
                notice "   $line"
            done
            echo >> "${MERGE_TO_FILE}" || fatal "Failed to write to ${MERGE_TO_FILE}.\nFailing command: echo >> \"${MERGE_TO_FILE}\""
            printf '%s\n' "${MERGE_FROM_LINES[@]}" >> "${MERGE_TO_FILE}" || fatal "Failed to add variables to ${MERGE_TO_FILE}"
        fi
    fi

}

test_env_merge_newonly() {
    #run_script 'env_merge_newonly'
    warn "CI does not test env_merge_newonly."
}
