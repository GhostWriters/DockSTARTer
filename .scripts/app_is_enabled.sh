#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_is_enabled() {
    local APPNAME=${1-}
    local VAR_FILE=${2:-$COMPOSE_ENV}
    local APP_ENABLED=$(run_script 'env_get' "${APPNAME}__ENABLED")
    if [[ ${APP_ENABLED} = "true" ]]; then
        return 0
    else
        return 1
    fi
}

test_app_is_enabled() {
    run_script 'app_is_enabled' WATCHTOWER
    notice "'app_is_enabled' WATCHTOWER returned $?"
    run_script 'app_is_enabled' APPTHATDOESNOTEXIST
    notice "'app_is_enabled' APPTHATDOESNOTEXIST returned $?"
    #warn "CI does not test app_is_enabled."
}
