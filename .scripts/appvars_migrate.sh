#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

appvars_migrate() {
    local APPNAME=${1-}
    APPNAME=${APPNAME^^}

    local FILENAME=${APPNAME,,}
    local APP_FOLDER="${TEMPLATES_FOLDER}/${FILENAME}"
    local MIGRATE_FILE="${APP_FOLDER}/${FILENAME}.migrate"

    if [[ -f ${MIGRATE_FILE} ]]; then
        local -a MIGRATE_LINES=()

        # Read "migrate" file into an array. Remove comments. Convert whitespace to single spaces. Remove empty lines.
        readarray -t MIGRATE_LINES < <(sed -E 's/#.*$//g ; s/\s+/ /g ; /^\s*$/d' "${MIGRATE_FILE}" || true)
        for line in "${MIGRATE_LINES[@]}"; do
            local MIGRATE_TO_VAR
            local MIGRATE_FROM_VAR

            MIGRATE_TO_VAR=${line%% *}
            MIGRATE_FROM_VAR=${line##"${MIGRATE_TO_VAR}" }
            MIGRATE_TO_VAR=${MIGRATE_TO_VAR/app:/${FILENAME}:}
            MIGRATE_FROM_VAR=${MIGRATE_FROM_VAR/app:/${FILENAME}:}

            notice "run_script 'env_rename' \"${MIGRATE_FROM_VAR}\" \"${MIGRATE_TO_VAR}\""
            run_script 'env_rename' "${MIGRATE_FROM_VAR}" "${MIGRATE_TO_VAR}"
        done
    fi
}

test_appvars_migrate() {
    run_script 'appvars_migrate' WATCHTOWER
}
