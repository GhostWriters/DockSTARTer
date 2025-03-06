#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

env_sanitize() {
    # Don't set WATCHTOWER_NETWORK_MODE to none
    local WATCHTOWER_NETWORK_MODE
    WATCHTOWER_NETWORK_MODE=$(run_script 'env_get' WATCHTOWER__NETWORK_MODE)
    if [[ ${WATCHTOWER_NETWORK_MODE} == "none" ]]; then
        run_script 'env_set' WATCHTOWER__NETWORK_MODE ""
    fi

    # Rename vars
    run_script 'env_migrate' DOCKERCONFDIR DOCKER_VOLUME_CONFIG
    run_script 'env_migrate' DOCKERGID DOCKER_GID
    run_script 'env_migrate' DOCKERHOSTNAME DOCKER_HOSTNAME
    run_script 'env_migrate' DOCKERSTORAGEDIR DOCKER_VOLUME_STORAGE

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
