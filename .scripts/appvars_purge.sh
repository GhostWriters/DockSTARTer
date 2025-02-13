#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

appvars_purge() {
    local APPNAME=${1-}
    APPNAME=${APPNAME^^}
    local FILENAME=${APPNAME,,}
    local APPVAR_LINES
    local APPVAR_ENV_LINES
    local APP_ENV_FILE="${APP_ENV_FOLDER}/${FILENAME}.env"
    APPVAR_LINES=$(run_script 'appvars_lines' "${APPNAME}")
    APPVAR_ENV_LINES=$(run_script 'env_lines' "${APP_ENV_FILE}")
    if [[ -z ${APPVAR_LINES} && -z ${APPVAR_ENV_LINES} ]]; then
        if [[ ${PROMPT-} == "GUI" ]]; then
            whiptail --fb --clear --title "DockSTARTer" --msgbox "${APPNAME} has no variables." 0 0
        else
            warn "${APPNAME} has no variables."
        fi
        return
    fi

    if [[ ${CI-} == true ]] || run_script 'question_prompt' "${PROMPT:-CLI}" Y "Would you like to purge these settings for ${APPNAME}?\\n\\n${COMPOSE_ENV}:\\n${APPVAR_LINES}\\n\\n${APP_ENV_FILE}:\\n${APPVAR_ENV_LINES}\\n"; then
        info "Purging ${APPNAME} .env variables."
        local -a APPVARS
        readarray -t APPVARS < <(run_script 'appvars_list' "${APPNAME}")
        local APPVARS_REGEX
        # Make a string of variables seperated by "|"
        APPVARS_REGEX=$(printf "%s|" "${APPVARS[@]}")
        # Remove the final "| at end of the string
        APPVARS_REGEX="${APPVARS_REGEX::-1}"
        sed -i -E "/^\s*(${APPVARS_REGEX})\s*=/d" "${COMPOSE_ENV}" || fatal "Failed to purge ${APPNAME} variables.\nFailing command: ${F[C]}sed -i -E \"/^\\\*(${APPVARS_REGEX})\\\*/d\" \"${COMPOSE_ENV}\""
    else
        info "Keeping ${APPNAME} .env variables."
    fi
}

test_appvars_purge() {
    run_script 'appvars_purge' WATCHTOWER
    run_script 'env_update'
    cat "${COMPOSE_ENV}"
}
