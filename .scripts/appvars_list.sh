#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

appvars_list() {
    local APPNAME=${1-}
    if [[ ${APPNAME} =~ ^[A-Za-z0-9_]+: ]]; then
        # APPNAME is in the form of "APPNAME:", list all variable in "env_files/appname.env"
        APPNAME=${APPNAME%%:*}
        local VAR_FILE="${APP_ENV_FOLDER}/${APPNAME,,}.env"
        run_script 'env_var_list' "${VAR_FILE}"
    else
        local VAR_REGEX="${APPNAME}__(?![A-Za-z0-9]+__)\w+"
        local APP_VARS_REGEX="\s*\K${VAR_REGEX}(?=\s*=)"
        grep --color=never -o -P "${APP_VARS_REGEX}" "${COMPOSE_ENV}" || true
    fi
}

test_appvars_list() {
    notice "[WATCHTOWER]"
    run_script 'appvars_list' WATCHTOWER
    notice "[RADARR__4K]"
    run_script 'appvars_list' RADARR__4K
    notice "[WATCHTOWER:]"
    run_script 'appvars_list' WATCHTOWER:
    notice "[RADARR__4K:]"
    run_script 'appvars_list' RADARR__4K:
    #warn "CI does not test app_vars_list."
}
