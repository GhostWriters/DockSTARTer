#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_list_installed() {
    local APPNAME_REGEX='^[A-Z][A-Z0-9]*(__[A-Z0-9]+)?'
    local INSTALLED_APPS_REGEX="${APPNAME_REGEX}(?=__ENABLED\s*=)"
    local -a INSTALLED_APPS
    local -a BUILTIN_APPS

    #notice "INSTALLED_APPS_REGEX [ ${INSTALLED_APPS_REGEX} ]"
    readarray -t INSTALLED_APPS < <(grep --color=never -o -P "${INSTALLED_APPS_REGEX}" "${COMPOSE_ENV}" || true)
    readarray -t BUILTIN_APPS < <(run_script 'app_list_builtin')
    local -a COMBINED=("${INSTALLED_APPS[@]}" "${BUILTIN_APPS[@]}")
    printf "%s\n" "${COMBINED[@]}" | sort | uniq -d
}

test_app_list_installed() {
    # run_script 'app_list_installed'
    warn "CI does not test app_list_installed."
}
