#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_is_user_defined() {
    local APPNAME=${1-}

    if ! run_script 'app_is_referenced' "${APPNAME}"; then
        false
        return
    fi
    if ! run_script 'env_var_exists' "${APPNAME^^}__ENABLED"; then
        false
        return
    fi
    if ! run_script 'app_is_builtin' "${APPNAME}"; then
        false
        return
    fi
    true
    return
}

test_app_is_user_defined() {
    for AppName in WATCHTOWER SAMBA RADARR NONEXISTENTAPP; do
        local Result="no"
        if run_script 'app_is_user_defined' "${AppName}"; then
            Result="YES"
        fi
        notice "[${AppName}] [${Result}]"
    done
}
