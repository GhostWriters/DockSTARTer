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
    local -A APP_VAR_MIGRATE

    # Build variable values lookup array, APP_VAR_VALUES["variable"]="default value"
    {
        # Read all lines with labels into temporary APP_LABEL_LINES array
        local -a APP_LABEL_LINES
        mapfile -t APP_LABEL_LINES < <(grep --color=never -P "\scom\.dockstarter\.appvars\.\K[\w]+" "${APPLABELFILE}" || true)
        if [[ -z ${APP_LABEL_LINES[*]} ]]; then
            error "Unable to find labels for ${APPNAME}"
            return
        fi
        debug "appvars_creates.sh: ${APP_LABEL_LINES[*]@A}"

        for line in "${APP_LABEL_LINES[@]}"; do
            local SET_VAR
            local SET_VAL
            debug "appvars_create.sh: ${line@A}"
            SET_VAR=$(echo "$line" | grep --color=never -Po "\scom\.dockstarter\.appvars\.\K[\w]+")
            debug "appvars_create.sh: ${SET_VAR@A}"
            SET_VAL=$(echo "$line" | grep --color=never -Po "\scom\.dockstarter\.appvars\.${SET_VAR}: \K.*" | sed -E 's/^([^"].*[^"])$/"\1"/' | xargs || true)
            debug "appvars_create.sh: ${SET_VAL@A}"
            if [[ -n ${SET_VAR} ]]; then
                APP_VAR_VALUE["${SET_VAR^^}"]=${SET_VAL}
            fi
        done
    }
    debug "appvars_create.sh: ${APP_VAR_VALUE[*]@A}"

    # Build migrate variable lookup array, APP_MIGRATE_VAR["variable"]="migrate from variable"
    for SET_VAR in "${!APP_VAR_VALUE[@]}"; do
        local APPNAME=${SET_VAR%%_*}
        local REST_VAR=${SET_VAR#"${APPNAME}_"}
        local VAR_TYPE=${REST_VAR%%_*}
        case "${VAR_TYPE}" in
            ENVIRONMENT | VOLUME)
                REST_VAR=${REST_VAR#"${VAR_TYPE}"}
                local MIGRATE_VAR="${APPNAME}${REST_VAR}"
                # shellcheck disable=SC2076
                if [[ !  " ${MIGRATE_VAR} " =~ " ${!APP_VAR_VALUE[*]} " ]]; then
                    # Potential "migrate from" variable isn't an existing app variable, add it to the migrate list
                    APP_VAR_MIGRATE["${SET_VAR}"]=${MIGRATE_VAR}
                fi
                ;;
        esac
    done
    debug "appvars_create.sh: ${APP_VAR_MIGRATE[*]@A}"

    # Actual processing starts here
    info "Creating environment variables for ${APPNAME}."
    for SET_VAR in "${!APP_VAR_VALUE[@]}"; do
        if grep -q -P "^${SET_VAR}=" "${COMPOSE_ENV}"; then
            # Variable already exists
            continue
        fi

        local MIGRATE_VAR=${APP_VAR_MIGRATE["${SET_VAR}"]-}
        if [[ -n ${MIGRATE_VAR} ]] && grep -q -P "^${MIGRATE_VAR}=" "${COMPOSE_ENV}"; then
            # Migrate old variable
            run_script 'env_rename' "${MIGRATE_VAR}" "${SET_VAR}"
        else
            # Add new variable
            local DEFAULT_VAL=${APP_VAR_VALUE["${SET_VAR}"]}
            notice "Adding ${SET_VAR}='${DEFAULT_VAL}' in ${COMPOSE_ENV} file."
            run_script 'env_set' "${SET_VAR}" "${DEFAULT_VAL}"
        fi
    done
    run_script 'env_set' "${APPNAME}_ENABLED" true
}

test_appvars_create() {
    run_script 'appvars_create' WATCHTOWER
    run_script 'env_update'
    cat "${COMPOSE_ENV}"
}
