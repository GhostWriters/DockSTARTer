#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_is_builtin() {
    local APPNAME=${1-}

    local BaseApp
    BaseApp="$(run_script 'appname_to_baseappname' "${APPNAME}")"
    [[ -d "${TEMPLATES_FOLDER}/${BaseApp}" ]]
}

test_app_is_builtin() {
    run_script 'app_is_builtin' WATCHTOWER
    notice "'app_is_builtin' WATCHTOWER returned $?"
    run_script 'app_is_builtin' APPTHATDOESNOTEXIST
    notice "'app_is_builtin' APPTHATDOESNOTEXIST returned $?"
    warn "CI does not test app_is_builtin."
}
