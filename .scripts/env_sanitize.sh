#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

env_sanitize() {
    if grep -q '=~' "${SCRIPTPATH}/compose/.env"; then
        info "Replacing ~ with ${DETECTED_HOMEDIR} in ${SCRIPTPATH}/compose/.env file."
        sed -i "s/=~/=$(sed 's/[&/\]/\\&/g' <<< "${DETECTED_HOMEDIR}")/g" "${SCRIPTPATH}/compose/.env" | warning "Please verify that ~ is not used in ${SCRIPTPATH}/compose/.env file."
    fi

    local OUROBOROS_ENABLED
    OUROBOROS_ENABLED=$(run_script 'env_get' OUROBOROS_ENABLED)
    local WATCHTOWER_ENABLED
    WATCHTOWER_ENABLED=$(run_script 'env_get' WATCHTOWER_ENABLED)
    if [[ ${OUROBOROS_ENABLED} == true ]] && [[ ${WATCHTOWER_ENABLED} == true ]]; then
        run_script 'env_set' WATCHTOWER_ENABLED false
    fi

    local OUROBOROS_NETWORK_MODE
    OUROBOROS_NETWORK_MODE=$(run_script 'env_get' OUROBOROS_NETWORK_MODE)
    if [[ ${OUROBOROS_NETWORK_MODE} == "none" ]]; then
        run_script 'env_set' OUROBOROS_NETWORK_MODE ""
    fi

    local WATCHTOWER_NETWORK_MODE
    WATCHTOWER_NETWORK_MODE=$(run_script 'env_get' WATCHTOWER_NETWORK_MODE)
    if [[ ${WATCHTOWER_NETWORK_MODE} == "none" ]]; then
        run_script 'env_set' WATCHTOWER_NETWORK_MODE ""
    fi
}

test_env_sanitize() {
    run_script 'env_sanitize'
}
