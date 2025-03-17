#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_list() {
    local -a APPS
    local APPS
    readarray -t APPS < <(run_script 'app_nicename' "$(run_script 'app_list_builtin')")
    for index in "${!APPS[@]}"; do
        local APPNAME=${APPS[index]}
        APPS[index]+=','
        if run_script 'app_is_depreciated' "${APPNAME}"; then
            APPS[index]+='[*DEPRECIATED*]'
        fi
        APPS[index]+=','
        if run_script 'app_is_added' "${APPNAME}"; then
            APPS[index]+='*ADDED*'
            if run_script 'app_is_disabled' "${APPNAME}"; then
                APPS[index]+=',(Disabled)'
            fi
        fi
    done
    printf '%s\n' "${APPS[@]}" | column -t -s ','
}

test_app_list() {
    run_script 'app_list'
    # warn "CI does not test app_list."
}
