#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_is_disabled() {
    local APPNAME=${1-}
    APPNAME=${APPNAME^^}
    if ! run_script 'app_is_builtin' "${APPNAME}"; then
        false
        return
    fi
    local APP_ENABLED
    APP_ENABLED="$(run_script 'env_get' "${APPNAME}__ENABLED")"
    [[ ${APP_ENABLED} != "true" ]]
}

test_app_is_disabled() {
    run_script 'app_is_disabled' WATCHTOWER
    notice "'app_is_disabled' WATCHTOWER returned $?"
    run_script 'app_is_disabled' APPTHATDOESNOTEXIST
    notice "'app_is_disabled' APPTHATDOESNOTEXIST returned $?"
    #warn "CI does not test app_is_disabled."
}
