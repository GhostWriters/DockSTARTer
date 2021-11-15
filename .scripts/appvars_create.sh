#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

appvars_create() {
    local APPNAME=${1:-}
    APPNAME=${APPNAME^^}
    local FILENAME=${APPNAME,,}
    local APPTEMPLATES="${SCRIPTPATH}/compose/.apps/${FILENAME}"
    info "Creating environment variables for ${APPNAME}."
    while IFS= read -r line; do
        local VAR_LABEL=${line}
        local SET_VAR=${VAR_LABEL^^}
        if grep -q -P "^${SET_VAR}=" "${COMPOSE_ENV}"; then
            continue
        fi

        local DEFAULT_VAL
        DEFAULT_VAL=$(grep --color=never -Po "\scom\.dockstarter\.appvars\.${VAR_LABEL}: \K.*" "${APPTEMPLATES}/${FILENAME}.labels.yml" | sed -E 's/^([^"].*[^"])$/"\1"/' | xargs || true)
        echo "${SET_VAR}=" >> "${COMPOSE_ENV}"
        run_script 'env_set' "${SET_VAR}" "${DEFAULT_VAL}"
    done < <(grep --color=never -Po "\scom\.dockstarter\.appvars\.\K[\w]+" "${APPTEMPLATES}/${FILENAME}.labels.yml" || error "Unable to find labels for ${APPNAME}")
    run_script 'env_set' "${APPNAME}_ENABLED" true
}

test_appvars_create() {
    run_script 'env_update'
    run_script 'appvars_create' WATCHTOWER
    cat "${COMPOSE_ENV}"
}
