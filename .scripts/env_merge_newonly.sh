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
        readarray -t MERGE_FROM_LINES < <(sed -n "s/^\s*\([A-Za-z0-9_]*\)\s*=/\1=/p" "${MERGE_FROM_FILE}" || true)
        for line in "${MERGE_FROM_LINES[@]}"; do
            local VARNAME
            VARNAME="${line%%=*}"
            if ! grep --color=never -q -P "^\s*${VARNAME}\s*=\K.*" "${MERGE_TO_FILE}"; then
                notice "Adding ${line} in ${MERGE_TO_FILE} file."
                printf '\n%s\n' "${line}" >> "${MERGE_TO_FILE}"
            fi
        done
    fi

}

test_env_merge_newonly() {
    #run_script 'env_merge_newonly'
    warn "CI does not test env_merge_newonly."
}
