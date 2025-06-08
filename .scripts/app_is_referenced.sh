#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_is_referenced() {
    local APPNAME=${1:-}

    if [[ -z "$(run_script 'appvars_list' "${APPNAME}")" ]]; then
        if [[ -z "$(run_script 'appvars_list' "${APPNAME}:")" ]]; then
            false
            return
        fi
    fi
    true
    return
}

test_app_is_referenced() {
    for AppName in WATCHTOWER SAMBA RADARR NONEXISTENTAPP; do
        local Referenced="no"
        if run_script 'app_is_referenced' "${AppName}"; then
            Referenced="YES"
        fi
        notice "[${AppName}] [${Referenced}]"
    done
}
