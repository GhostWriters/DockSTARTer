#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

appvars_migrate() {
    local -u APPNAME=${1-}
    local -l appname=${APPNAME}

    local MIGRATE_FILE
    MIGRATE_FILE="$(run_script 'app_instance_file' "${appname}" "*.migrate")"

    if [[ -f ${MIGRATE_FILE} ]]; then
        local -a MigrateLines=()
        # Read "migrate" file into an array. Remove comments. Convert whitespace to single spaces. Remove empty lines.
        readarray -t MigrateLines < <(sed -E 's/#.*$//g ; s/\s+/ /g ; /^\s*$/d' "${MIGRATE_FILE}" || true)
        for line in "${MigrateLines[@]}"; do
            local ToVar="${line%% *}"
            local FromVar="${line##"${ToVar}" }"
            ToVar="${ToVar// /}"
            FromVar="${FromVar// /}"
            if [[ -n ${FromVar} && -n ${ToVar} ]]; then
                run_script 'env_migrate' "${FromVar}" "${ToVar}"
            fi
        done
    fi
}

test_appvars_migrate() {
    run_script 'appvars_migrate' WATCHTOWER
}
