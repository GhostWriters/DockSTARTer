#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

appvars_list() {
    local APPNAME=${1-}
    local VAR_REGEX="${APPNAME}__(?![A-Za-z0-9]+__)\w+"
    local APP_VARS_REGEX="\s*\K${VAR_REGEX}(?=\s*=)"
    grep --color=never -o -P "${APP_VARS_REGEX}" "${COMPOSE_ENV}" || true
}

test_appvars_list() {
    run_script 'appvars_list' WATCHTOWER
    run_script 'appvars_list' RADARR__4K
    #warn "CI does not test app_vars_list."
}
