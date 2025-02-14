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
        notice "Checking migrations for ${APPNAME}"
        local -a MIGRATE_LINES=()
        # Read "migrate" file into an array. Remove comments. Convert whitespace to single spaces. Remove empty lines.
        readarray -t MIGRATE_LINES < <(sed -E 's/#.*$//g ; s/\s+/ /g ; /^\s*$/d' "${MIGRATE_FILE}")
        if [[ -n ${MIGRATE_LINES[*]-} ]]; then
            for line in ${MIGRATE_LINES[@]}; do
                local MIGRATE_TO
                local MIGRATE_FROM
                MIGRATE_TO=${line%% *}
                MIGRATE_FROM=${line##${MIGRATE_TO} }
                MIGRATE_TO=${MIGRATE_TO/app:/${FILENAME}:}
                notice "[${MIGRATE_TO}] [${MIGRATE_FROM}]"
            done
        fi
    fi
}

test_appvars_migrate() {
    run_script 'appvars_migrate' WATCHTOWER
}
