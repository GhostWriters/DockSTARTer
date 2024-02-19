#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

env_sanitize() {
    # Don't set WATCHTOWER_NETWORK_MODE to none
    local WATCHTOWER_NETWORK_MODE
    WATCHTOWER_NETWORK_MODE=$(run_script 'env_get' WATCHTOWER_NETWORK_MODE)
    if [[ ${WATCHTOWER_NETWORK_MODE} == "none" ]]; then
        run_script 'env_set' WATCHTOWER_NETWORK_MODE ""
    fi

    # Rename apps
    run_script 'rename_app' LETSENCRYPT SWAG
    run_script 'rename_app' MINECRAFT_BEDROCK_SERVER MINECRAFTBEDROCKSERVER
    run_script 'rename_app' MINECRAFT_SERVER MINECRAFTSERVER

    # Rename vars
    run_script 'rename_var' DOCKERCONFDIR DOCKER_VOLUME_CONFIG
    run_script 'rename_var' DOCKERGID DOCKER_GID
    run_script 'rename_var' DOCKERHOSTNAME DOCKER_HOSTNAME
    run_script 'rename_var' DOCKERSTORAGEDIR DOCKER_VOLUME_STORAGE

    # Migrate from old app vars
    if grep -q -P '\b([^_]+)_(?!(ENABLED|ENVIRONMENT_|NETWORK_MODE|PORT_|RESTART|TAG|VOLUME_))' "${COMPOSE_ENV}"; then
        while IFS= read -r line; do
            local VAR_VAL=${line}
            local SET_VAR=${VAR_VAL%%=*}
            local APPNAME=${SET_VAR%%_*}
            local REST_VAR=${SET_VAR#*_}
            local NEW_VAR="${SET_VAR}"
            case "${SET_VAR}" in
                COMPOSE_HTTP_TIMEOUT | DOCKER_GID | DOCKER_HOSTNAME)
                    continue
                    ;;
                *DIR | *DIR_*)
                    NEW_VAR="${APPNAME}_VOLUME_${REST_VAR}"
                    ;;
                *)
                    NEW_VAR="${APPNAME}_ENVIRONMENT_${REST_VAR}"
                    ;;
            esac
            if [[ ${SET_VAR} != "${NEW_VAR}" ]]; then
                run_script 'rename_var' "${SET_VAR}" "${NEW_VAR}"
            fi
        done < <(grep --color=never -P '\b([^_]+)_(?!(ENABLED|ENVIRONMENT_|NETWORK_MODE|PORT_|RESTART|TAG|VOLUME_))' "${COMPOSE_ENV}")
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
