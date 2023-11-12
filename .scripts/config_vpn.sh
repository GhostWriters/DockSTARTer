#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

config_vpn() {
    local APPNAME="VPN"
    local VARNAMES=(LAN_NETWORK NS1 NS2 VPN_ENABLE VPN_CLIENT VPN_PROV VPN_OVPNDIR VPN_WGDIR VPN_USER VPN_PASS VPN_OPTIONS)
    local APPVARS
    APPVARS=$(for v in "${VARNAMES[@]}"; do echo "${v}=$(run_script 'env_get' "${v}")"; done)

    local DEFAULT
    local MESSAGE
    if grep -q -P 'VPN_ENABLED='"'"'?true'"'"'?$' "${COMPOSE_ENV}"; then
        DEFAULT="N"
        MESSAGE="Would you like to keep these settings for ${APPNAME}?\\n You have apps enabled that will use these variables.\\n\\n${APPVARS}"
    else
        DEFAULT="Y"
        MESSAGE="Would you like to keep these settings for ${APPNAME}?\\n You do not have apps enabled that will use these variables.\\n\\n${APPVARS}"
    fi

    if run_script 'question_prompt' "${PROMPT-}" "${DEFAULT}" "${MESSAGE}"; then
        info "Keeping ${APPNAME} .env variables."
    else
        info "Configuring ${APPNAME} .env variables."
        while IFS= read -r line; do
            local SET_VAR=${line%%=*}
            run_script 'menu_value_prompt' "${SET_VAR}" || return 1
        done < <(echo "${APPVARS}")
    fi
}

test_config_vpn() {
    # run_script 'config_vpn'
    warn "CI does not test config_vpn."
}
