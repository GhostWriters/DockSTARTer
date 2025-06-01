#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_list_added() {
    local APPNAME_REGEX='^[A-Z][A-Z0-9]*(__[A-Z0-9]+)?'
    local ADDED_APPS_REGEX="${APPNAME_REGEX}(?=__ENABLED\s*=)"
    local -a ADDED_APPS
    local -a BUILTIN_APPS

    #notice "ADDED_APPS_REGEX [ ${ADDED_APPS_REGEX} ]"
    readarray -t ADDED_APPS < <(grep --color=never -o -P "${ADDED_APPS_REGEX}" "${COMPOSE_ENV}" || true)
    readarray -t BUILTIN_APPS < <(run_script 'app_list_builtin')
    local -a COMBINED=("${ADDED_APPS[@]-}" "${BUILTIN_APPS[@]-}")
    printf "%s\n" "${COMBINED[@]-}" | sort | uniq -d
}

test_app_list_added() {
    # run_script 'app_list_added'
    warn "CI does not test app_list_added."
}
