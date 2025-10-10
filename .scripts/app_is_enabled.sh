#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_is_enabled() {
    local -u APPNAME=${1-}
    if ! run_script 'app_is_builtin' "${APPNAME}"; then
        false
        return
    fi
    is_true "$(run_script 'env_get' "${APPNAME}__ENABLED")"
}

test_app_is_enabled() {
    run_script 'app_is_enabled' WATCHTOWER
    notice "'app_is_enabled' WATCHTOWER returned $?"
    run_script 'app_is_enabled' APPTHATDOESNOTEXIST
    notice "'app_is_enabled' APPTHATDOESNOTEXIST returned $?"
    #warn "CI does not test app_is_enabled."
}
