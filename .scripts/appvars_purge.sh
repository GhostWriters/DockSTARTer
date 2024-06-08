#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

appvars_purge() {
    local APPNAME=${1-}
    APPNAME=${APPNAME^^}
    local APPVARS
    APPVARS=$(grep --color=never -P "^${APPNAME}_" "${COMPOSE_ENV}" || true)
    if [[ -z ${APPVARS} ]]; then
        if [[ ${PROMPT-} == "GUI" ]]; then
            whiptail --fb --clear --title "DockSTARTer" --msgbox "${APPNAME} has no variables." 0 0
        else
            warn "${APPNAME} has no variables."
        fi
        return
    fi

    if [[ ${CI-} == true ]] || run_script 'question_prompt' "${PROMPT:-CLI}" Y "Would you like to purge these settings for ${APPNAME}?\\n\\n${APPVARS}"; then
        info "Purging ${APPNAME} .env variables."
        sed -i "/^${APPNAME}_/d" "${COMPOSE_ENV}" || fatal "Failed to purge ${APPNAME} variables.\nFailing command: ${F[C]}sed -i \"/^${APPNAME}_/d\" \"${COMPOSE_ENV}\""
    else
        info "Keeping ${APPNAME} .env variables."
    fi
}

test_appvars_purge() {
    run_script 'appvars_purge' WATCHTOWER
    run_script 'env_update'
    cat "${COMPOSE_ENV}"
}
