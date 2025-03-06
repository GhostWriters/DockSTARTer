#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

env_migrate() {
    local FROM_VAR=${1-}
    local TO_VAR=${2-}
    local FROM_VAR_FILE=${3:-$COMPOSE_ENV}
    local TO_VAR_FILE=${4:-$FROM_VAR_FILE}

    # Change the .env file to use `appname.env' if 'appname:' preceeds the variable name, and remove 'appname:' from the string
    if [[ ${FROM_VAR} == *":"* ]]; then
        FROM_VAR_FILE="${APP_ENV_FOLDER}/${FROM_VAR%:*}.env"
        FROM_VAR="${FROM_VAR#*:}"
    fi
    if [[ ${TO_VAR} == *":"* ]]; then
        TO_VAR_FILE="${APP_ENV_FOLDER}/${TO_VAR%:*}.env"
        TO_VAR="${TO_VAR#*:}"
    fi

    if [[ ! -f ${TO_VAR_FILE} ]]; then
        # Destination file does not exist, create it
        notice "Creating ${TO_VAR_FILE}"
        touch "${TO_VAR_FILE}"
    fi

    if [[ ${FROM_VAR_FILE} == "${TO_VAR_FILE}" ]]; then
        # Renaming variables in the same file (possibly handle override migrations here)
        local VAR_FILE=${FROM_VAR_FILE}
        local -a FOUND_VAR_LIST=()
        readarray -t FOUND_VAR_LIST < <(grep -o -P "^\s*\K${FROM_VAR}(?=\s*=)" "${VAR_FILE}" || true)
        for FOUND_VAR in "${FOUND_VAR_LIST[@]}"; do
            if run_script 'override_var_exists' "${FOUND_VAR}"; then
                # Variable exists in user's override file, copy instead of rename
                run_script 'env_copy' "${FOUND_VAR}" "${TO_VAR}" "${VAR_FILE}"
            else
                run_script 'env_rename' "${FOUND_VAR}" "${TO_VAR}" "${VAR_FILE}"
            fi
        done
    else
        # Renaming variables in different files
        local -a FOUND_VAR_LIST=()
        readarray -t FOUND_VAR_LIST < <(grep -o -P "^\s*\K${FROM_VAR}(?=\s*=)" "${FROM_VAR_FILE}" || true)
        for FOUND_VAR in "${FOUND_VAR_LIST[@]}"; do
            if run_script 'override_var_exists' "${FOUND_VAR}"; then
                # Variable exists in user's override file, copy instead of move
                run_script 'env_copy' "${FOUND_VAR}" "${TO_VAR}" "${FROM_VAR_FILE}" "${TO_VAR_FILE}"
            else
                run_script 'env_rename' "${FOUND_VAR}" "${TO_VAR}" "${FROM_VAR_FILE}" "${TO_VAR_FILE}"
            fi
        done
    fi
}

test_env_migrate() {
    # run_script 'env_migrate'
    warn "CI does not test env_migrate."
}
