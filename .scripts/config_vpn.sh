#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

config_vpn() {
    local APPNAME
    APPNAME="VPN"
    local VARNAMES
    VARNAMES=(LAN_NETWORK NS1 NS2 VPN_ENABLE VPN_USER VPN_PASS VPN_PROV VPN_OPTIONS)
    local APPVARS
    APPVARS=$(for v in "${VARNAMES[@]}"; do echo "${v}=$(run_script 'env_get' "${v}")"; done)

    local DEFAULT
    local MESSAGE
    if grep -q 'VPN_ENABLED=true$' "${SCRIPTPATH}/compose/.env"; then
        DEFAULT="N"
        MESSAGE="Would you like to keep these settings for ${APPNAME}?\\n You have apps enabled that will use these variables.\\n\\n${APPVARS}"
    else
        DEFAULT="Y"
        MESSAGE="Would you like to keep these settings for ${APPNAME}?\\n You do not have apps enabled that will use these variables.\\n\\n${APPVARS}"
    fi

    if run_script 'question_prompt' "${DEFAULT}" "${MESSAGE}"; then
        info "Keeping ${APPNAME} .env variables."
    else
        info "Configuring ${APPNAME} .env variables."
        while IFS= read -r line; do
            SET_VAR=${line%%=*}
            run_script 'menu_value_prompt' "${SET_VAR}" || return 1
        done < <(echo "${APPVARS}")
    fi
}

test_config_vpn() {
    # run_script 'config_vpn'
    warning "Travis does not test config_vpn."
}
