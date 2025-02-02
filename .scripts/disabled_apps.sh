#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

disabled_apps() {
    local APPNAME_REGEX='^[A-Z][A-Z0-9]*(__[A-Z0-9]+)?'
    local FALSE_REGEX="('?false'?)"
    local DISABLED_REGEX="__ENABLED\s*=${FALSE_REGEX}"
    local DISABLED_APPS_REGEX="${APPNAME_REGEX}(?=${DISABLED_REGEX})"

    #notice "DISABLED_APPS_REGEX [ ${DISABLED_APPS_REGEX} ]"
    grep --color=never -o -P "${DISABLED_APPS_REGEX}" "${COMPOSE_ENV}" | sort || true
}

test_disabled_apps() {
    # run_script 'disabled_apps'
    warn "CI does not test disabled_apps."
}
