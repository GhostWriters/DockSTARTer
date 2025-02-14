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
                local MIGRATE_TO_FILE
                local MIGRATE_FROM_FILE

                MIGRATE_TO=${line%% *}
                MIGRATE_FROM=${line##${MIGRATE_TO} }
                MIGRATE_TO=${MIGRATE_TO/app:/${FILENAME}:}
                MIGRATE_FROM=${MIGRATE_FROM/app:/${FILENAME}:}
                MIGRATE_TO_FILE=${COMPOSE_ENV}
                MIGRATE_FROM_FILE=${COMPOSE_ENV}

                # Change the .env file to use if specified in the variable, and remove the appname from the string
                if [[ ${MIGRATE_TO} == *":"* ]]; then
                    MIGRATE_TO_FILE="${APP_ENV_FOLDER}/${MIGRATE_TO%:*}.env"
                    MIGRATE_TO="${MIGRATE_TO#*:}"
                fi
                if [[ ${MIGRATE_FROM} == *":"* ]]; then
                    MIGRATE_FROM_FILE="${APP_ENV_FOLDER}/${MIGRATE_FROM%:*}.env"
                    MIGRATE_FROM="${MIGRATE_FROM#*:}"
                fi

                notice "[${MIGRATE_TO}] [${MIGRATE_TO_FILE}] [${MIGRATE_FROM}] [${MIGRATE_FROM_FILE}]"
                if ! run_script 'env_var_exists' "${MIGRATE_TO}"; then
                    notice "${MIGRATE_TO} does not exist, check for migrations"
                    local VAR_LIST=()
                    if [[ ${MIGRATE_TO_FILE} = ${MIGRATE_FROM_FILE} ]]; then
                        # Migrating from and to the same file, do a replace
                        notice "Migrating from and to the same file, do a replace"
                        local VAR_LIST=()
                        readarray -t VAR_LIST < <(grep --color=never -o -P "^\s*\K(?:${MIGRATE_FROM})(?=\s*=)" "${MIGRATE_FROM_FILE}")
                        notice "VAR_LIST [${VAR_LIST[*]-}]"
                    else
                        # Migrating from and to different files, do a copy and delete
                        notice "Migrating from and to different files, do a copy and delete"
                    fi
                else
                    notice "${MIGRATE_TO} variable exists, don't try to migrate"
                fi
            done
        fi
    fi
}

test_appvars_migrate() {
    run_script 'appvars_migrate' WATCHTOWER
}
