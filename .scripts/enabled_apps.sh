#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

enabled_apps() {
    local APPNAME_REGEX='^[A-Z][A-Z0-9]*(__[A-Z0-9]+)?'
    local TRUE_REGEX="('?true'?)"
    local ENABLED_REGEX="__ENABLED\s*=${TRUE_REGEX}"
    local ENABLED_APPS_REGEX="${APPNAME_REGEX}(?=${ENABLED_REGEX})"

    #notice "ENABLED_APPS_REGEX [ ${ENABLED_APPS_REGEX} ]"
    grep --color=never -o -P "${ENABLED_APPS_REGEX}" "${COMPOSE_ENV}" | sort || true
}

test_enabled_apps() {
    # run_script 'enabled_apps'
    warn "CI does not test enabled_apps."
}
