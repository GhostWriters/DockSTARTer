#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_is_referenced() {
    local APPNAME=${1:-}

    # Check for app variables in the global .env file
    if [[ -n $(run_script 'appvars_list' "${APPNAME}") ]]; then
        return 0
    fi

    # Check for app variables in the .env.app.appname file
    if [[ -n $(run_script 'appvars_list' "${APPNAME}:") ]]; then
        return 0
    fi

    # Check for an un-commented reference to .env.app.appname in the override file
    if [[ -f ${COMPOSE_OVERRIDE} ]]; then
        local AppEnvFile
        AppEnvFile="$(basename "$(run_script 'app_env_file' "${APPNAME}")")"
        local SearchString="${AppEnvFile//./[.]}"
        if grep -q -P "^(?:[^#]*)(?:^|\s)(?<Q>['\"]?)${SearchString}(?=\k<Q>\s|$)" "${COMPOSE_OVERRIDE}" &> /dev/null; then

            return 0
        fi
    fi

    return 1
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
