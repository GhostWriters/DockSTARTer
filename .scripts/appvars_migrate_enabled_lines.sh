#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=(
    grep
)

appvars_migrate_enabled_lines() {
    local OldSuffix="_ENABLED"
    local NewSuffix="__ENABLED"
    local -a AppList
    readarray -t AppList < <(${GREP} --color=never -o -P "^\s*\K[A-Z][A-Z0-9]*(?=${OldSuffix}\s*=)" "${COMPOSE_ENV}" | sort -u || true)
    if [[ -n ${AppList[*]} ]]; then
        for APPNAME in "${AppList[@]}"; do
            run_script 'env_rename' "${APPNAME}${OldSuffix}" "${APPNAME}${NewSuffix}"
        done
    fi
}

test_appvars_migrate_enabled_lines() {
    # run_script 'appvars_migrate_enabled_lines'
    warn "CI does not test appvars_migrate_enabled_lines."
}
