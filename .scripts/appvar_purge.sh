#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

appvar_purge() {
    local APPNAME=${1:-}
    local APPVARS
    APPVARS=$(grep "^${APPNAME}_" "${SCRIPTPATH}/compose/.env" || true)
    if [[ -z ${APPVARS} ]]; then
        if [[ ${CI:-} == true ]] && [[ ${TRAVIS:-} == true ]]; then
            warning "${APPNAME} has no variables."
        else
            whiptail --fb --clear --title "DockSTARTer" --msgbox "${APPNAME} has no variables." 0 0
        fi
        return
    fi

    if run_script 'question_prompt' Y "Would you like to purge these settings for ${APPNAME}?\\n\\n${APPVARS}"; then
        info "Purging ${APPNAME} .env variables."
        sed -i "/^${APPNAME}_/d" "${SCRIPTPATH}/compose/.env" || fatal "Failed to purge ${APPNAME} variables."
    else
        info "Keeping ${APPNAME} .env variables."
    fi
}

test_appvar_purge() {
    run_script 'appvar_purge' WATCHTOWER
    error "TESTS ARE NOT YET CREATED."
}
