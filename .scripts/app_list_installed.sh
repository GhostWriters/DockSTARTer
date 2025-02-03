#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_list_installed() {
    local APPNAME_REGEX='^[A-Z][A-Z0-9]*(__[A-Z0-9]+)?'
    local INSTALLED_APPS_REGEX="${APPNAME_REGEX}(?=__ENABLED\s*=)"

    #notice "INSTALLED_APPS_REGEX [ ${INSTALLED_APPS_REGEX} ]"
    grep --color=never -o -P "${INSTALLED_APPS_REGEX}" "${COMPOSE_ENV}" | sort || true
}

test_app_list_installed() {
    # run_script 'app_list_installed'
    warn "CI does not test app_list_installed."
}
