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

    # Rename vars
    run_script 'env_rename' DOCKERCONFDIR DOCKER_VOLUME_CONFIG
    run_script 'env_rename' DOCKERGID DOCKER_GID
    run_script 'env_rename' DOCKERHOSTNAME DOCKER_HOSTNAME
    run_script 'env_rename' DOCKERSTORAGEDIR DOCKER_VOLUME_STORAGE

    # Rename apps
    run_script 'appvars_rename' LETSENCRYPT SWAG
    run_script 'appvars_rename' MINECRAFT_BEDROCK_SERVER MINECRAFTBEDROCKSERVER
    run_script 'appvars_rename' MINECRAFT_SERVER MINECRAFTSERVER

    # Migrate from old app vars
    while IFS= read -r line; do
        local VAR_VAL=${line}
        local SET_VAR=${VAR_VAL%%=*}
        local APPNAME=${SET_VAR%%_*}
        local REST_VAR=${SET_VAR#*_}
        local NEW_VAR="${SET_VAR}"
        case "${SET_VAR}" in
            COMPOSE_HTTP_TIMEOUT | DOCKER_GID | DOCKER_HOSTNAME | PGID | PUID | TZ)
                # Global vars that should be untouched
                continue
                ;;
            DOCKERLOGGING_MAXFILE | DOCKERLOGGING_MAXSIZE | \
                LAN_NETWORK | NS1 | NS2 | \
                VPN_CLIENT | VPN_ENABLE | VPN_OPTIONS | VPN_OVPNDIR | VPN_PASS | VPN_PROV | VPN_USER | VPN_WGDIR)
                # Legacy vars that should be untouched
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
            run_script 'env_rename' "${SET_VAR}" "${NEW_VAR}"
        fi
    done < <(grep --color=never -P '\b[A-Z0-9]+_(?!(ENABLED|ENVIRONMENT_|NETWORK_MODE|PORT_|RESTART|TAG|VOLUME_))' "${COMPOSE_ENV}")

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
