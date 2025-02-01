#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

appvars_migrate_enabled_lines() {
    local OLD_SUFFIX="_ENABLED"
    local NEW_SUFFIX="__ENABLED"
    local -a APPS
    readarray -t APPS < <(grep --color=never -o -P "^\s*\K[A-Z][A-Z0-9]*(?=${OLD_SUFFIX}\s*=)" "${COMPOSE_ENV}" | sort || true)
    if [[ -n ${APPS[@]} ]]; then
        for APPNAME in ${APPS[@]}; do
            notice "Renaming ${APPNAME}${OLD_SUFFIX} to ${APPNAME}${NEW_SUFFIX} in ${COMPOSE_ENV} file."
            sed -i "s/^\s*${APPNAME}${OLD_SUFFIX}\s*=/${APPNAME}${NEW_SUFFIX}=/" "${COMPOSE_ENV}" || fatal "Failed to rename var from ${APPNAME}${OLD_SUFFIX} to ${APPNAME}${NEW_SUFFIX}\nFailing command: ${F[C]}sed -i \"s/^\\s*${APPNAME}${OLD_SUFFIX}\\s*=/${APPNAME}${NEW_SUFFIX}=/\" \"${COMPOSE_ENV}\""
        done
    fi
}

test_appvars_migrate_enabled_lines() {
    # run_script 'appvars_migrate_enabled_lines'
    warn "CI does not test appvars_migrate_enabled_lines."
}
