#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

appvars_create() {
    local APPNAME=${1-}
    APPNAME=${APPNAME^^}
    local APPSFOLDER="${SCRIPTPATH}/compose/.apps"
    local FILENAME=${APPNAME,,}
    local APPTEMPLATES="${APPSFOLDER}/${FILENAME}"
    local APPLABELFILE="${APPTEMPLATES}/${FILENAME}.labels.yml"
    mapfile -t APP_LABEL_LIST < <(grep --color=never -Po "\scom\.dockstarter\.appvars\.\K[\w]+" "${APPLABELFILE}" || true)
    APP_LABEL_LIST=("${APP_LABEL_LIST[@]^^}")
    local APP_LABEL_SEARCH
    APP_LABEL_SEARCH=$(IFS='|'; printf '^(%s)$' "${APP_LABEL_LIST[*]}")

    local -A LABEL_DEFAULT_VALUE
    local -A APP_MIGRATE_LIST
    for SET_VAR in "${APP_LABEL_LIST[@]}"; do
        local APPNAME=${SET_VAR%%_*}
        local REST_VAR=${SET_VAR#"${APPNAME}_"}
        local VAR_TYPE=${REST_VAR%%_*}
        case "${VAR_TYPE}" in
            ENVIRONMENT | VOLUME)
                REST_VAR=${REST_VAR#"${VAR_TYPE}"}
                local MIGRATE_VAR="${APPNAME}${REST_VAR}"
                if [[ ! ${MIGRATE_VAR} =~ ${APP_LABEL_SEARCH} ]]; then
                    APP_MIGRATE_LIST["${SET_VAR}"]=${MIGRATE_VAR}
                fi
                ;;
        esac
        LABEL_DEFAULT_VALUE["${SET_VAR}"]=$(grep --color=never -Po "\scom\.dockstarter\.appvars\.${SET_VAR,,}: \K.*" "${APPLABELFILE}" | sed -E 's/^([^"].*[^"])$/"\1"/' | xargs || true)
    done

    info "Creating environment variables for ${APPNAME}."
    if [[ -n ${APP_LABEL_LIST[*]} ]]; then
        for SET_VAR in "${APP_LABEL_LIST[@]}"; do
            if grep -q -P "^${SET_VAR}=" "${COMPOSE_ENV}"; then
                # Variable already exists
                continue
            fi

            local MIGRATE_VAR=${APP_MIGRATE_LIST["${SET_VAR}"]-}
            if [[ -n ${MIGRATE_VAR} ]]; then
                if grep -q -P "^${MIGRATE_VAR}=" "${COMPOSE_ENV}"; then
                    # Migrate old variable
                    run_script 'env_rename' "${MIGRATE_VAR}" "${SET_VAR}"
                    continue
                fi
            fi
            # Add new variable
            local DEFAULT_VAL=${LABEL_DEFAULT_VALUE["${SET_VAR}"]}
            notice "Adding ${SET_VAR}='${DEFAULT_VAL}' in ${COMPOSE_ENV} file."
            echo "${SET_VAR}=" >> "${COMPOSE_ENV}"
            run_script 'env_set' "${SET_VAR}" "${DEFAULT_VAL}"
        done
        run_script 'env_set' "${APPNAME}_ENABLED" true
    else
        error "Unable to find labels for ${APPNAME}"
    fi
}

test_appvars_create() {
    run_script 'env_update'
    run_script 'appvars_create' WATCHTOWER
    cat "${COMPOSE_ENV}"
}
