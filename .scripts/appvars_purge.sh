#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

appvars_purge() {
    local APPNAME=${1:-}
    APPNAME=${APPNAME^^}
    local APPVARS
    APPVARS=$(grep "^${APPNAME}_" "${SCRIPTPATH}/compose/.env" || true)
    if [[ -z ${APPVARS} ]]; then
        if [[ ${PROMPT:-} == "GUI" ]]; then
            whiptail --fb --clear --title "DockSTARTer" --msgbox "${APPNAME} has no variables." 0 0
        else
            warn "${APPNAME} has no variables."
        fi
        return
    fi

    if [[ ${CI:-} == true ]] || run_script 'question_prompt' "${PROMPT:-CLI}" Y "Would you like to purge these settings for ${APPNAME}?\\n\\n${APPVARS}"; then
        info "Purging ${APPNAME} .env variables."
        sed -i "/^${APPNAME}_/d" "${SCRIPTPATH}/compose/.env" || fatal "Failed to purge ${APPNAME} variables."
    else
        info "Keeping ${APPNAME} .env variables."
    fi
}

test_appvars_purge() {
    run_script 'env_update'
    run_script 'appvars_purge' WATCHTOWER
    cat "${SCRIPTPATH}/compose/.env"
}
