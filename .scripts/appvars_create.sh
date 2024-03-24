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

    local -A APP_VAR_VALUE
    local APP_VAR_SEARCH
    local -A APP_MIGRATE_VAR
    {
        local -a APP_LABEL_LINES
        mapfile -t APP_LABEL_LINES < <(grep --color=never -P "\scom\.dockstarter\.appvars\.\K[\w]+" "${APPLABELFILE}" || true)
        if [[ -z ${APP_LABEL_LINES[*]} ]]; then
            error "Unable to find labels for ${APPNAME}"
            return
        fi

        for line in ${APP_LABEL_LINES[@]}; do
            local SET_VAR
            local SET_VAL
            SET_VAR=$(echo "$line" | grep --color=never -Po "\scom\.dockstarter\.appvars\.\K[\w]+")
            SET_VAL=$(echo "$line" | grep --color=never -Po "\scom\.dockstarter\.appvars\.${SET_VAR}: \K.*" | sed -E 's/^([^"].*[^"])$/"\1"/' | xargs || true)
            [[ -n ${SET_VAR} ]] && APP_VAR_VALUE["${SET_VAR^^}"]=${SET_VAL}
        done
    }

    APP_VAR_SEARCH=$(
        IFS='|'
        printf '^(%s)$' "${!APP_VAR_VALUE[*]}"
    )

    for SET_VAR in "${!APP_VAR_VALUE[@]}"; do
        local APPNAME=${SET_VAR%%_*}
        local REST_VAR=${SET_VAR#"${APPNAME}_"}
        local VAR_TYPE=${REST_VAR%%_*}
        case "${VAR_TYPE}" in
            ENVIRONMENT | VOLUME)
                REST_VAR=${REST_VAR#"${VAR_TYPE}"}
                local MIGRATE_VAR="${APPNAME}${REST_VAR}"
                if [[ ! ${MIGRATE_VAR} =~ ${APP_VAR_SEARCH} ]]; then
                    APP_MIGRATE_VAR["${SET_VAR}"]=${MIGRATE_VAR}
                fi
                ;;
        esac
    done

    info "Creating environment variables for ${APPNAME}."
    for SET_VAR in "${!APP_VAR_VALUE[@]}"; do
        if grep -q -P "^${SET_VAR}=" "${COMPOSE_ENV}"; then
            # Variable already exists
            continue
        fi

        local MIGRATE_VAR=${APP_MIGRATE_VAR["${SET_VAR}"]-}
        if [[ -n ${MIGRATE_VAR} ]]; then
            if grep -q -P "^${MIGRATE_VAR}=" "${COMPOSE_ENV}"; then
                # Migrate old variable
                run_script 'env_rename' "${MIGRATE_VAR}" "${SET_VAR}"
                continue
            fi
        fi
        # Add new variable
        local DEFAULT_VAL=${APP_VAR_VALUE["${SET_VAR}"]}
        notice "Adding ${SET_VAR}='${DEFAULT_VAL}' in ${COMPOSE_ENV} file."
        echo "${SET_VAR}=" >> "${COMPOSE_ENV}"
        run_script 'env_set' "${SET_VAR}" "${DEFAULT_VAL}"
    done
    run_script 'env_set' "${APPNAME}_ENABLED" true
}

test_appvars_create() {
    run_script 'env_update'
    run_script 'appvars_create' WATCHTOWER
    cat "${COMPOSE_ENV}"
}
