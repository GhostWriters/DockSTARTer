#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

appvars_migrate_enabled_lines() {
    local OLD_SUFFIX="_ENABLED"
    local NEW_SUFFIX="__ENABLED"
    local -a APPS
    readarray -t APPS < <(grep --color=never -o -P "^\s*\K[A-Z][A-Z0-9]*(?=${OLD_SUFFIX}\s*=)" "${COMPOSE_ENV}" | sort -u || true)
    if [[ -n ${APPS[*]} ]]; then
        for APPNAME in "${APPS[@]}"; do
            run_script 'env_rename' "${APPNAME}${OLD_SUFFIX}" "${APPNAME}${NEW_SUFFIX}"
        done
    fi
}

test_appvars_migrate_enabled_lines() {
    # run_script 'appvars_migrate_enabled_lines'
    warn "CI does not test appvars_migrate_enabled_lines."
}
