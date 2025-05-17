#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

appvars_migrate() {
    local APPNAME=${1-}
    APPNAME=${APPNAME^^}
    local appname=${APPNAME,,}

    local APP_FOLDER="${TEMPLATES_FOLDER}/${appname}"
    local MIGRATE_FILE="${APP_FOLDER}/${appname}.migrate"

    if [[ -f ${MIGRATE_FILE} ]]; then
        local -a MigrateLines=()
        # Read "migrate" file into an array. Remove comments. Convert whitespace to single spaces. Remove empty lines.
        readarray -t MigrateLines < <(sed -E 's/#.*$//g ; s/\s+/ /g ; /^\s*$/d' "${MIGRATE_FILE}" || true)
        for line in "${MigrateLines[@]}"; do
            local ToVar
            local FromVar
            ToVar=${line%% *}
            FromVar=${line##"${ToVar}" }

            run_script 'env_migrate' "${FromVar}" "${ToVar}"
        done
    fi
}

test_appvars_migrate() {
    run_script 'appvars_migrate' WATCHTOWER
}
