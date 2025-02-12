#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

appvars_lines() {
    local APPNAME=${1-}
    local VAR_REGEX="${APPNAME}__(?![A-Za-z0-9]+__)\w+"
    local APP_VARS_REGEX="\s*${VAR_REGEX}\s*="
    grep --color=never -P "${APP_VARS_REGEX}" "${COMPOSE_ENV}" || true
}

test_appvars_lines() {
    run_script 'appvars_lines' WATCHTOWER
    run_script 'appvars_lines' RADARR__4K
    #warn "CI does not test appvars_lines."
}
