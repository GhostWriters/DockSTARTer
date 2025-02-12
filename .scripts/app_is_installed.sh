#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_is_installed() {
    local APPNAME=${1-}
    local VAR_FILE=${2:-$COMPOSE_ENV}
    local APPNAME_REGEX="^\s*${APPNAME^^}"
    local INSTALLED_APPS_REGEX="${APPNAME_REGEX}(?=__ENABLED\s*=)"

    if run_script 'app_is_builtin' "${APPNAME}"; then
        grep --color=never -q -P "${INSTALLED_APPS_REGEX}" "${VAR_FILE}"
        return $?
    else
        return 1
    fi
}

test_app_is_installed() {
    # run_script 'app_is_installed'
    run_script 'app_is_installed' WATCHTOWER
    notice "'app_is_installed' WATCHTOWER returned $?"
    run_script 'app_is_installed' APPTHATDOESNOTEXIST
    notice "'app_is_installed' APPTHATDOESNOTEXIST returned $?"
    warn "CI does not test app_is_installed."
}
