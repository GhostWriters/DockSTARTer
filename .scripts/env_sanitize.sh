#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

env_sanitize() {
    local GLOBAL_LAN_NETWORK
    GLOBAL_LAN_NETWORK="$(run_script 'env_get' GLOBAL_LAN_NETWORK)"
    if [[ -z ${GLOBAL_LAN_NETWORK-} ]] || echo "${GLOBAL_LAN_NETWORK-}" | grep -q 'x'; then
        # GLOBAL_LAN_NETWORK is either empty or contains an `x`, set it to the detected lan network
        run_script 'env_set_literal' GLOBAL_LAN_NETWORK "$(run_script 'var_default_value' GLOBAL_LAN_NETWORK)"
    fi
    local DOCKER_GID
    DOCKER_GID="$(run_script 'env_get' DOCKER_GID)"
    if [[ -z ${DOCKER_GID-} ]] || echo "${DOCKER_GID-}" | grep -q 'x'; then
        # DOCKER_GID is either empty or contains an `x`, set it to the detected Docker GID
        run_script 'env_set_literal' DOCKER_GID "$(run_script 'var_default_value' DOCKER_GID)"
    fi
    DOCKER_VOLUME_CONFIG="$(run_script 'env_get' DOCKER_VOLUME_CONFIG)"
    if [[ -z ${DOCKER_VOLUME_CONFIG-} ]]; then
        # DOCKER_VOLUME_CONFIG is either empty, set it to the default
        run_script 'env_set_literal' DOCKER_VOLUME_CONFIG "$(run_script 'var_default_value' DOCKER_VOLUME_CONFIG)"
    fi
    if [[ -z ${DOCKER_VOLUME_STORAGE-} ]]; then
        # DOCKER_VOLUME_STORAGE is either empty, set it to the default
        run_script 'env_set_literal' DOCKER_VOLUME_STORAGE "$(run_script 'var_default_value' DOCKER_VOLUME_STORAGE)"
    fi

    # Don't set WATCHTOWER_NETWORK_MODE to none
    local WATCHTOWER_NETWORK_MODE
    WATCHTOWER_NETWORK_MODE="$(run_script 'env_get' WATCHTOWER__NETWORK_MODE)"
    if [[ ${WATCHTOWER_NETWORK_MODE-} == "none" ]]; then
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
