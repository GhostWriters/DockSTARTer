#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_is_builtin() {
    local -l appname=${1-}

    local -l baseapp
    baseapp="$(run_script 'appname_to_baseappname' "${appname}")"
    [[ -d "${TEMPLATES_FOLDER}/${baseapp}" ]]
}

test_app_is_builtin() {
    run_script 'app_is_builtin' WATCHTOWER
    notice "'app_is_builtin' WATCHTOWER returned $?"
    run_script 'app_is_builtin' APPTHATDOESNOTEXIST
    notice "'app_is_builtin' APPTHATDOESNOTEXIST returned $?"
    warn "CI does not test app_is_builtin."
}
