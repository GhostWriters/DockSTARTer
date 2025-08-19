#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_is_added() {
    # Returns if the passed app is both built in and an APPNAME__ENABLED variable exists
    local -u APPNAME=${1-}
    local ENABLED_VAR="${APPNAME}__ENABLED"
    run_script 'app_is_builtin' "${APPNAME}" && run_script 'env_var_exists' "${ENABLED_VAR}"
}

test_app_is_added() {
    # run_script 'app_is_added'
    run_script 'app_is_added' WATCHTOWER
    notice "'app_is_added' WATCHTOWER returned $?"
    run_script 'app_is_added' APPTHATDOESNOTEXIST
    notice "'app_is_added' APPTHATDOESNOTEXIST returned $?"
}
