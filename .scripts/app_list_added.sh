#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=(
    grep
)

app_list_added() {
    local APPNAME_REGEX='[A-Z][A-Z0-9]*(__[A-Z0-9]+)?'
    local ADDED_APPS_REGEX="^${APPNAME_REGEX}(?=__ENABLED\s*=)"
    local -a AddedApps

    readarray -t AddedApps < <(${GREP} --color=never -o -P "${ADDED_APPS_REGEX}" "${COMPOSE_ENV}" || true)
    for AppName in "${AddedApps[@]-}"; do
        if run_script 'app_is_builtin' "${AppName}"; then
            echo "${AppName}"
        fi
    done
}

test_app_list_added() {
    # run_script 'app_list_added'
    warn "CI does not test app_list_added."
}
