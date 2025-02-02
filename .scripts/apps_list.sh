#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

apps_list() {
    local -a APPS
    local APPS
    readarray -t APPS < <(run_script 'builtin_apps')
    for index in "${!APPS[@]}"; do
        local APPNAME=${APPS[index]}
        APPS[index]+=','
        if run_script 'app_is_installed' "${APPNAME}"; then
            APPS[index]+='*INSTALLED*,'
            if run_script 'app_is_enabled' "${APPNAME}"; then
                APPS[index]+='*ENABLED*'
            else
                APPS[index]+='*DISABLED*'
            fi
        else
            APPS[index]+=','
        fi
        APPS[index]+=','
        #if run_script 'app_is_depreciated' "${APPNAME}"; then
        #    APPS[index]+='(DEPRECIATED)'
        #fi
    done
    printf '%s\n' "${APPS[@]}" | column -t -s ','
}

test_apps_list() {
    run_script 'apps_list'
    # warn "CI does not test apps_list."
}
