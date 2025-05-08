#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

env_sanitize() {
    local GLOBAL_LAN_NETWORK
    GLOBAL_LAN_NETWORK=$(run_script 'env_get' GLOBAL_LAN_NETWORK)
    if echo "${GLOBAL_LAN_NETWORK}" | grep -q 'x'; then
        local DETECTED_LAN_NETWORK
        DETECTED_LAN_NETWORK=$(run_script 'detect_lan_network')
        run_script 'env_set' GLOBAL_LAN_NETWORK "${DETECTED_LAN_NETWORK}"
    fi

    # Don't set WATCHTOWER_NETWORK_MODE to none
    local WATCHTOWER_NETWORK_MODE
    WATCHTOWER_NETWORK_MODE=$(run_script 'env_get' WATCHTOWER__NETWORK_MODE)
    if [[ ${WATCHTOWER_NETWORK_MODE} == "none" ]]; then
        run_script 'env_set' WATCHTOWER__NETWORK_MODE ""
    fi

    # Replace ~ with /home/username
    if grep -q -P '^\w+_VOLUME_\w+=~/' "${COMPOSE_ENV}"; then
        info "Replacing ~ with ${DETECTED_HOMEDIR} in ${COMPOSE_ENV} file."
        sed -i -E "s/^(\w+_VOLUME_\w+)=~\//\1=$(sed 's/[&/\]/\\&/g' <<< "${DETECTED_HOMEDIR}")\//g" "${COMPOSE_ENV}" | warn "Please verify that ~ is not used in ${COMPOSE_ENV} file."
    fi

}

test_env_sanitize() {
    run_script 'appvars_create' WATCHTOWER
    run_script 'env_sanitize'
    run_script 'appvars_purge' WATCHTOWER
}
