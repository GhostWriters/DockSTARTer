#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

appvars_lines() {
    # Return all lines in `.env` file for app APPNAME
    # If APPNAME ends in a ':', returns all lines in `.env.app.appname'
    # If APPNAME is empty, return all lines in `.env` file that are not for an app
    local -u APPNAME=${1-}
    local VAR_FILE=${2:-$COMPOSE_ENV}

    if [[ -z ${APPNAME} ]]; then
        # Search for all variables not for an app
        local VAR_REGEX='[A-Z][A-Z0-9]*(__[A-Z0-9]+)+\w+'
        local APP_VARS_REGEX="^\s*${VAR_REGEX}\s*="
        grep -v -P '^\s*$|^\s*\#' "${VAR_FILE}" | grep --color=never -v -P "${APP_VARS_REGEX}" || true
    elif [[ ${APPNAME} =~ ^[A-Z0-9_]+: ]]; then
        # APPNAME is in the form of "APPNAME:", list all variable lines in "appname.env"
        APPNAME=${APPNAME%%:*}
        VAR_FILE="$(run_script 'app_env_file' "${APPNAME}")"
        run_script 'env_lines' "${VAR_FILE}"
    else
        # Search for all variables for app "APPNAME"
        local VAR_REGEX="${APPNAME}__(?![A-Za-z0-9]+__)\w+"
        local APP_VARS_REGEX="^\s*${VAR_REGEX}\s*="
        grep --color=never -P "${APP_VARS_REGEX}" "${VAR_FILE}" || true
    fi
}

test_appvars_lines() {
    notice "[WATCHTOWER]"
    run_script 'appvars_lines' WATCHTOWER
    notice "[RADARR__4K]"
    run_script 'appvars_lines' RADARR__4K
    notice "[WATCHTOWER:]"
    run_script 'appvars_lines' WATCHTOWER:
    notice "[RADARR__4K:]"
    run_script 'appvars_lines' RADARR__4K:
    notice "[]"
    run_script 'appvars_lines' ''
    #warn "CI does not test appvars_lines."
}
