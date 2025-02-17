#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_list_referenced() {
    local APPNAME_REGEX='^[A-Z][A-Z0-9]*(__[A-Z0-9]+)?'
    local REFERENCED_APPS_REGEX="${APPNAME_REGEX}(?=__ENABLED\s*=)"

    grep --color=never -o -P "${REFERENCED_APPS_REGEX}" "${COMPOSE_ENV}" | sort -u  || true
}

test_app_list_referenced() {
    run_script 'app_list_referenced'
    #warn "CI does not test app_list_referenced."
}
