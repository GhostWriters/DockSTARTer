#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

env_sanitize() {
    # Replace ~ with /home/username
    if grep -q -P '^\w+DIR=~/' "${COMPOSE_ENV}"; then
        info "Replacing ~ with ${DETECTED_HOMEDIR} in ${COMPOSE_ENV} file."
        sed -i -E "s/^(\w+DIR)=~\//\1=$(sed 's/[&/\]/\\&/g' <<< "${DETECTED_HOMEDIR}")\//g" "${COMPOSE_ENV}" | warn "Please verify that ~ is not used in ${COMPOSE_ENV} file."
    fi

    # Set LAN_NETWORK using detect_lan_network
    local LAN_NETWORK
    LAN_NETWORK=$(run_script 'env_get' LAN_NETWORK)
    if grep -q -P 'x' <<< "${LAN_NETWORK}" || [[ ${LAN_NETWORK} == "" ]]; then
        local DETECTED_LAN_NETWORK
        DETECTED_LAN_NETWORK=$(run_script 'detect_lan_network')
        run_script 'env_set' LAN_NETWORK "${DETECTED_LAN_NETWORK}"
    fi

    # Don't run Ouroboros and Watchtower at the same time
    local OUROBOROS_ENABLED
    OUROBOROS_ENABLED=$(run_script 'env_get' OUROBOROS_ENABLED)
    local WATCHTOWER_ENABLED
    WATCHTOWER_ENABLED=$(run_script 'env_get' WATCHTOWER_ENABLED)
    if [[ ${OUROBOROS_ENABLED} == true ]] && [[ ${WATCHTOWER_ENABLED} == true ]]; then
        run_script 'env_set' OUROBOROS_ENABLED false
    fi

    # Don't set OUROBOROS_NETWORK_MODE to none
    local OUROBOROS_NETWORK_MODE
    OUROBOROS_NETWORK_MODE=$(run_script 'env_get' OUROBOROS_NETWORK_MODE)
    if [[ ${OUROBOROS_NETWORK_MODE} == "none" ]]; then
        run_script 'env_set' OUROBOROS_NETWORK_MODE ""
    fi

    # Don't set WATCHTOWER_NETWORK_MODE to none
    local WATCHTOWER_NETWORK_MODE
    WATCHTOWER_NETWORK_MODE=$(run_script 'env_get' WATCHTOWER_NETWORK_MODE)
    if [[ ${WATCHTOWER_NETWORK_MODE} == "none" ]]; then
        run_script 'env_set' WATCHTOWER_NETWORK_MODE ""
    fi

    # Migrate from LetsEncrypt to SWAG
    local LETSENCRYPT_ENABLED
    LETSENCRYPT_ENABLED=$(run_script 'env_get' LETSENCRYPT_ENABLED)
    local SWAG_ENABLED
    SWAG_ENABLED=$(run_script 'env_get' SWAG_ENABLED)
    if [[ ${LETSENCRYPT_ENABLED} == true ]] && [[ ${SWAG_ENABLED} != true ]]; then
        notice "Migrating from LETSENCRYPT to SWAG."
        docker stop letsencrypt || warn "Failed to stop letsencrypt container.\nFailing command: ${F[C]}docker stop letsencrypt"
        notice "Moving config folder."
        local DOCKERCONFDIR
        DOCKERCONFDIR=$(run_script 'env_get' DOCKERCONFDIR)
        mv "${DOCKERCONFDIR}/letsencrypt" "${DOCKERCONFDIR}/swag" || fatal "Failed to move folder.\nFailing command: ${F[C]}mv \"${DOCKERCONFDIR}/letsencrypt\" \"${DOCKERCONFDIR}/swag\""
        notice "Migrating vars."
        sed -i "s/^LETSENCRYPT_/SWAG_/" "${COMPOSE_ENV}" || fatal "Failed to migrate vars from LETSENCRYPT_ to SWAG_\nFailing command: ${F[C]}sed -i \"s/^LETSENCRYPT_/SWAG_/\" \"${COMPOSE_ENV}\""
        run_script 'appvars_create' SWAG
        notice "Completed migrating from LETSENCRYPT to SWAG. Run ${F[C]}ds -c${NC} to create the new container."
    fi
}

test_env_sanitize() {
    run_script 'appvars_create' OUROBOROS
    run_script 'appvars_create' WATCHTOWER
    run_script 'env_sanitize'
    run_script 'appvars_purge' OUROBOROS
    run_script 'appvars_purge' WATCHTOWER
}
