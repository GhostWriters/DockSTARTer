#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

menu_app_vars() {
    local APPNAME
    APPNAME=${1:-}
    local APPVARS
    APPVARS=$(grep -v "^${APPNAME}_ENABLED=" "${SCRIPTPATH}/compose/.env" | grep "^${APPNAME}_")

    if [[ -z ${APPVARS} ]]; then
        whiptail --fb --clear --title "DockSTARTer" --msgbox "${APPNAME} has no variables to configure." 0 0
        return
    fi

    local ANSWER
    set +e
    ANSWER=$(whiptail --fb --clear --title "DockSTARTer" --yesno "Would you like to keep these settings for ${APPNAME}?\\n\\n${APPVARS}" 0 0 3>&1 1>&2 2>&3; echo $?)
    set -e
    if [[ ${ANSWER} != 0 ]]; then
        while IFS= read -r line; do
            SET_VAR=${line/=*/}
            run_script 'menu_value_prompt' "${SET_VAR}" || return 1
        done < <(echo "${APPVARS}")
    fi
}
