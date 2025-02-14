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
        readarray -t MIGRATE_LINES < <(sed -E 's/#.*$//g ; s/\s+/ /g ; /^\s*$/d' "${MIGRATE_FILE}")
        if [[ -n ${MIGRATE_LINES[*]-} ]]; then
            for line in "${MIGRATE_LINES[@]}"; do
                local MIGRATE_TO_VAR
                local MIGRATE_FROM_REGEX
                local MIGRATE_TO_FILE
                local MIGRATE_FROM_FILE

                MIGRATE_TO_VAR=${line%% *}
                MIGRATE_FROM_REGEX=${line##"${MIGRATE_TO_VAR}" }
                MIGRATE_TO_VAR=${MIGRATE_TO_VAR/app:/${FILENAME}:}
                MIGRATE_FROM_REGEX=${MIGRATE_FROM_REGEX/app:/${FILENAME}:}

                MIGRATE_TO_FILE=${COMPOSE_ENV}
                MIGRATE_FROM_FILE=${COMPOSE_ENV}

                # Change the .env file to use if specified in the variable, and remove the appname from the string
                if [[ ${MIGRATE_TO_VAR} == *":"* ]]; then
                    MIGRATE_TO_FILE="${APP_ENV_FOLDER}/${MIGRATE_TO_VAR%:*}.env"
                    MIGRATE_TO_VAR="${MIGRATE_TO_VAR#*:}"
                fi
                if [[ ${MIGRATE_FROM_REGEX} == *":"* ]]; then
                    MIGRATE_FROM_FILE="${APP_ENV_FOLDER}/${MIGRATE_FROM_REGEX%:*}.env"
                    MIGRATE_FROM_REGEX="${MIGRATE_FROM_REGEX#*:}"
                fi

                if ! run_script 'env_var_exists' "${MIGRATE_TO_VAR}" "${MIGRATE_TO_FILE}"; then
                    local VAR_LIST=()
                    if [[ ${MIGRATE_TO_FILE} == "${MIGRATE_FROM_FILE}" ]]; then
                        # Migrating from and to the same file, do a replace
                        local MIGRATE_FROM_LIST=()
                        readarray -t MIGRATE_FROM_LIST < <(grep --color=never -o -P "^\s*\K(${MIGRATE_FROM_REGEX})(?=\s*=)" "${MIGRATE_FROM_FILE}")
                        for MIGRATE_FROM_VAR in "${MIGRATE_FROM_LIST[@]}"; do
                            if [[ -n ${MIGRATE_FROM_VAR} ]]; then
                                run_script 'env_rename' "${MIGRATE_FROM_VAR}" "${MIGRATE_TO_VAR}" "${MIGRATE_FROM_FILE}"
                            fi
                        done
                    else
                        # Migrating from and to different files, do a copy and delete
                        notice "Migrating from and to different files, do a copy and delete"
                    fi
                fi
            done
        fi
    fi
}

test_appvars_migrate() {
    run_script 'appvars_migrate' WATCHTOWER
}
