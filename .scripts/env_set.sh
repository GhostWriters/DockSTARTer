#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

env_set() {
    local SET_VAR=${1-}
    local NEW_VAL
    # https://unix.stackexchange.com/questions/422165/escape-double-quotes-in-variable/422170#422170
    NEW_VAL=$(printf "%s\n" "${2-}" | sed -e "s/'/'\"'\"'/g" -e "1s/^/'/" -e "\$s/\$/'/")
    local VAR_FILE=${3:-$COMPOSE_ENV}

    sed -i "/^\s*${SET_VAR}\s*=/d" "${VAR_FILE}" || true
    echo "${SET_VAR}=${NEW_VAL}" >> "${VAR_FILE}" || fatal "Failed to set ${SET_VAR}=${NEW_VAL}\nFailing command: ${F[C]} \"echo ${SET_VAR}=${NEW_VAL}\" >> \"${VAR_FILE}\""
}

test_env_set() {
    run_script 'appvars_create' WATCHTOWER
    run_script 'env_set' WATCHTOWER_ENABLED false
    run_script 'env_get' WATCHTOWER_ENABLED
    run_script 'appvars_purge' WATCHTOWER
}
