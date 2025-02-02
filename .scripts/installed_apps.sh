#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

installed_apps() {
    local APPNAME_REGEX='^[A-Z][A-Z0-9]*(__[A-Z0-9]+)?'
    local INSTALLED_APPS_REGEX="${APPNAME_REGEX}(?=__ENABLED\s*=)"

    #notice "INSTALLED_APPS_REGEX [ ${INSTALLED_APPS_REGEX} ]"
    grep --color=never -o -P "${INSTALLED_APPS_REGEX}" "${COMPOSE_ENV}" | sort || true
}

test_installed_apps() {
    # run_script 'installed_apps'
    warn "CI does not test installed_apps."
}
