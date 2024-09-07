#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

appvars_create() {
    local APPNAME=${1-}
    APPNAME=${APPNAME^^}
    local FILENAME=${APPNAME,,}
    local APPTEMPLATES="${SCRIPTPATH}/compose/.apps/${FILENAME}"
    local APPLABELFILE="${APPTEMPLATES}/${FILENAME}.labels.yml"

    local -A APP_VAR_VALUE
    local -A APP_VAR_MIGRATE

    # Build variable values lookup array, APP_VAR_VALUES["variable"]="default value"
    {
        # Read all lines with labels into temporary APP_LABEL_LINES array
        local -a APP_LABEL_LINES
        readarray -t APP_LABEL_LINES < <(grep --color=never -P "\scom\.dockstarter\.appvars\.\K[\w]+" "${APPLABELFILE}" || true)
        if [[ -z ${APP_LABEL_LINES[*]} ]]; then
            error "Unable to find labels for ${APPNAME}"
            return
        fi

        for line in "${APP_LABEL_LINES[@]}"; do
            local SET_VAR
            local SET_VAL
            SET_VAR=$(echo "$line" | grep --color=never -Po "\scom\.dockstarter\.appvars\.\K[\w]+")
            SET_VAL=$(echo "$line" | grep --color=never -Po "\scom\.dockstarter\.appvars\.${SET_VAR}: \K.*" | sed -E 's/^([^"].*[^"])$/"\1"/' | xargs || true)
            if [[ -n ${SET_VAR} ]]; then
                APP_VAR_VALUE["${SET_VAR^^}"]=${SET_VAL}
            fi
        done
    }

    # Build migrate variable lookup array, APP_MIGRATE_VAR["variable"]="migrate from variable"
    for SET_VAR in "${!APP_VAR_VALUE[@]}"; do
        local APPNAME=${SET_VAR%%_*}
        local REST_VAR=${SET_VAR#"${APPNAME}_"}
        local VAR_TYPE=${REST_VAR%%_*}
        case "${VAR_TYPE}" in
            ENVIRONMENT | VOLUME)
                REST_VAR=${REST_VAR#"${VAR_TYPE}"}
                local MIGRATE_VAR="${APPNAME}${REST_VAR}"
                # shellcheck disable=SC2199
                if [[ " ${!APP_VAR_VALUE[@]} " != *" ${MIGRATE_VAR} "* ]]; then
                    # Potential "migrate from" variable isn't an existing app variable, add it to the migrate list
                    APP_VAR_MIGRATE["${SET_VAR}"]=${MIGRATE_VAR}
                fi
                ;;
        esac
    done

    # Actual processing starts here
    info "Creating environment variables for ${APPNAME}."
    for SET_VAR in "${!APP_VAR_VALUE[@]}"; do
        if grep -q -P "^\s*${SET_VAR}\s*=" "${COMPOSE_ENV}"; then
            # Variable already exists
            continue
        fi

        local MIGRATE_VAR=${APP_VAR_MIGRATE["${SET_VAR}"]-}
        if [[ -n ${MIGRATE_VAR} ]] && grep -q -P "^\s*${MIGRATE_VAR}\s*=" "${COMPOSE_ENV}"; then
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
