#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_is_referenced() {
    local APPNAME=${1-}
    APPNAME=${APPNAME^^}
    local APPNAME_REGEX="${APPNAME^^}"
    local REFERENCED_APPS_REGEX="^\s*${APPNAME_REGEX}__[A-Za-z0-9]*"

    grep -q -P "${REFERENCED_APPS_REGEX}" "${COMPOSE_ENV}" &> /dev/null
}

test_app_is_referenced() {
    for AppName in WATCHTOWER SAMBA RADARR NONEXISTENTAPP; do
        local Referenced="no"
        if run_script 'app_is_referenced' "${AppName}"; then
            Referenced="YES"
        fi
        notice "[${AppName}] [${Referenced}]"
    done
}
