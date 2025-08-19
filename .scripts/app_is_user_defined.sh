#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_is_user_defined() {
    local -u APPNAME=${1-}

    if ! run_script 'app_is_builtin' "${APPNAME}"; then
        true
        return
    fi
    if ! run_script 'env_var_exists' "${APPNAME}__ENABLED"; then
        true
        return
    fi
    false
    return
}

test_app_is_user_defined() {
    for AppName in WATCHTOWER SAMBA RADARR NZBGET NONEXISTENTAPP; do
        local Result="no"
        if run_script 'app_is_user_defined' "${AppName}"; then
            Result="YES"
        fi
        notice "[${AppName}] [${Result}]"
    done
}
