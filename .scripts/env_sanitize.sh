#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

env_sanitize() {
    if grep -q -E '^\w+DIR=~/' "${SCRIPTPATH}/compose/.env"; then
        info "Replacing ~ with ${DETECTED_HOMEDIR} in ${SCRIPTPATH}/compose/.env file."
        sed -i -E "s/^(\w+DIR)=~\//\1=$(sed 's/[&/\]/\\&/g' <<< "${DETECTED_HOMEDIR}")\//g" "${SCRIPTPATH}/compose/.env" | warn "Please verify that ~ is not used in ${SCRIPTPATH}/compose/.env file."
    fi

    local LAN_NETWORK
    LAN_NETWORK=$(run_script 'env_get' LAN_NETWORK)
    if echo "${LAN_NETWORK}" | grep -q 'x' || [[ ${LAN_NETWORK} == "" ]]; then
        local DETECTED_LAN_NETWORK
        DETECTED_LAN_NETWORK=$(run_script 'detect_lan_network')
        run_script 'env_set' LAN_NETWORK "${DETECTED_LAN_NETWORK}"
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

    # TEMPORARY
    # There is no good place to put this code that makes sense to keep permanently
    # This code should be removed after allowing a period of time for existing users to upgrade
    local VPN_OVPNDIR
    VPN_OVPNDIR=$(run_script 'env_get' VPN_OVPNDIR)
    if grep -q 'VPN_ENABLED=true$' "${SCRIPTPATH}/compose/.env" && [[ ${VPN_OVPNDIR} != "" ]]; then
        mkdir -p "${VPN_OVPNDIR}" || fatal "${VPN_OVPNDIR} folder could not be created."
        run_script 'set_permissions' "${VPN_OVPNDIR}"
        local DOCKERCONFDIR
        DOCKERCONFDIR=$(run_script 'env_get' DOCKERCONFDIR)
        find "${DOCKERCONFDIR}" -regex '.*\/openvpn\/.*\.ovpn$' -exec cp {} "${VPN_OVPNDIR}" \; | info "No ovpn files to found."
        find "${DOCKERCONFDIR}" -regex '.*\/openvpn\/.*\.crt$' -exec cp {} "${VPN_OVPNDIR}" \; | info "No crt files to found."
    fi
}

test_env_sanitize() {
    run_script 'appvars_create' OUROBOROS
    run_script 'appvars_create' WATCHTOWER
    run_script 'env_sanitize'
    run_script 'appvars_purge' PORTAINER
    run_script 'appvars_purge' WATCHTOWER
}
