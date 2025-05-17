#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_list_enabled() {
    local APPNAME_REGEX='^[A-Z][A-Z0-9]*(__[A-Z0-9]+)?'
    local TRUE_REGEX="('?true'?)"
    local ENABLED_REGEX="__ENABLED\s*=${TRUE_REGEX}"
    local ENABLED_APPS_REGEX="${APPNAME_REGEX}(?=${ENABLED_REGEX})"
    local -a ENABLED_APPS
    local -a BUILTIN_APPS

    #notice "ENABLED_APPS_REGEX [ ${ENABLED_APPS_REGEX} ]"
    readarray -t ENABLED_APPS < <(grep --color=never -o -P "${ENABLED_APPS_REGEX}" "${COMPOSE_ENV}" | sort || true)
    readarray -t BUILTIN_APPS < <(run_script 'app_list_builtin')
    local -a COMBINED=("${ENABLED_APPS[@]}" "${BUILTIN_APPS[@]}")
    printf "%s\n" "${COMBINED[@]}" | sort | uniq -d
}

test_app_list_enabled() {
    # run_script 'app_list_enabled'
    warn "CI does not test app_list_enabled."
}
