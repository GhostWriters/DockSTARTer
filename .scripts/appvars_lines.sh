#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

appvars_lines() {
    # Return all lines in `.env` file for app APPNAME
    # If APPNAME is empty, return all lines in `.env` file that are not for an app
    local APPNAME=${1-}
    APPNAME=${APPNAME^^}
    if [[ -n ${APPNAME} ]]; then
        # Search for all variables for app "APPNAME"
        local VAR_REGEX="(${APPNAME}__(?![A-Za-z0-9]+__)\w+)"
        local APP_VARS_REGEX="^\s*${VAR_REGEX}\s*="
        grep --color=never -P "${APP_VARS_REGEX}" || true
    else
        # Search for all variables not for an app
        local VAR_REGEX='^[A-Z][A-Z0-9]*(__[A-Z0-9]+)+\w+'
        local APP_VARS_REGEX="^\s*${VAR_REGEX}\s*="
        grep -v -P '^\s*$|^\s*\#' "${COMPOSE_ENV}" | grep --color=never -v -P "${APP_VARS_REGEX}" || true
    fi
}

test_appvars_lines() {
    notice "[WATCHTOWER]"
    run_script 'appvars_lines' WATCHTOWER
    notice "[RADARR__4K]"
    run_script 'appvars_lines' RADARR__4K
    notice "[]"
    run_script 'appvars_lines' ''
    #warn "CI does not test appvars_lines."
}
