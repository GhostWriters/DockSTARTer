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

    local ANSWER
    if grep -q 'VPN_ENABLED=true$' "${SCRIPTPATH}/compose/.env"; then
        set +e
        ANSWER=$(whiptail --fb --clear --title "DockSTARTer" --defaultno --yesno "Would you like to keep these settings for ${APPNAME}?\\n\\n${APPVARS}" 0 0 3>&1 1>&2 2>&3; echo $?)
        set -e
    else
        set +e
        ANSWER=$(whiptail --fb --clear --title "DockSTARTer" --yesno "Would you like to keep these settings for ${APPNAME}?\\n\\n${APPVARS}" 0 0 3>&1 1>&2 2>&3; echo $?)
        set -e
    fi
    if [[ ${ANSWER} != 0 ]]; then
        while IFS= read -r line; do
            SET_VAR=${line/=*/}
            run_script 'menu_value_prompt' "${SET_VAR}" || return 1
        done < <(echo "${APPVARS}")
    fi
}
