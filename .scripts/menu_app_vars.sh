#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

menu_app_vars() {
    local APPNAME
    APPNAME=${1:-}
    local APPVARS
    APPVARS=$(grep -v "^${APPNAME}_ENABLED=" "${SCRIPTPATH}/compose/.env" | grep "^${APPNAME}_")
    if [[ -z ${APPVARS} ]]; then
        if [[ ${CI:-} == true ]] && [[ ${TRAVIS:-} == true ]]; then
            warning "${APPNAME} has no variables to configure."
        else
            whiptail --fb --clear --title "DockSTARTer" --msgbox "${APPNAME} has no variables to configure." 0 0
        fi
        return
    fi

    if run_script 'question_prompt' Y "Would you like to keep these settings for ${APPNAME}?\\n\\n${APPVARS}"; then
        info "Keeping ${APPNAME} .env variables."
    else
        info "Configuring ${APPNAME} .env variables."
        while IFS= read -r line; do
            SET_VAR=${line%%=*}
            run_script 'menu_value_prompt' "${SET_VAR}" || return 1
        done < <(echo "${APPVARS}")
    fi
}

test_menu_app_vars() {
    # run_script 'menu_app_vars'
    warning "Travis does not test menu_app_vars."
}
