#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_is_referenced() {
    local APPNAME=${1-)
    APPNAME=${APPNAME^^}
    local APPNAME_REGEX="${APPNAME^^})"
    local REFERENCED_APPS_REGEX="^\s*${APPNAME_REGEX}(?=__[A-Za-z0-9]\w*\s*=)"

    grep -q -P "${REFERENCED_APPS_REGEX}" "${COMPOSE_ENV}" &> /dev/null
}

test_app_is_referenced() {
    run_script 'app_list_referenced'
    #warn "CI does not test app_list_referenced."
}
