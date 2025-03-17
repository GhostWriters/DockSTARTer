#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_list_added() {
    readarray -t REFERENCED_APPS < <(run_script 'app_list_referenced')
    readarray -t BUILTIN_APPS < <(run_script 'app_list_builtin')
    local -a COMBINED=("${REFERENCED_APPS[@]}" "${BUILTIN_APPS[@]}")
    printf "%s\n" "${COMBINED[@]}" | sort | uniq -d
}

test_app_list_added() {
    # run_script 'app_list_added'
    warn "CI does not test app_list_added."
}
