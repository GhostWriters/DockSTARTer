#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

appvars_create() {
    local APPNAME=${1:-}
    APPNAME=${APPNAME^^}
    local FILENAME=${APPNAME,,}
    info "Creating environment variables for ${APPNAME}."
    while IFS= read -r line; do
        local VAR_LABEL
        VAR_LABEL=$(echo "${line}" | grep -Po "^com\.dockstarter\.appvars\.\K[\w]+" || true)
        if [[ -z ${VAR_LABEL} ]]; then
            continue
        fi

        local SET_VAR=${VAR_LABEL^^}
        if grep -q "^${SET_VAR}=" "${SCRIPTPATH}/compose/.env"; then
            continue
        fi

        local DEFAULT_VAL
        DEFAULT_VAL=$(grep -Po "\scom\.dockstarter\.appvars\.${VAR_LABEL}: \K.*" "${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.labels.yml" | sed -E 's/^([^"].*[^"])$/"\1"/' | xargs || true)
        echo "${SET_VAR}=" >> "${SCRIPTPATH}/compose/.env"
        run_script 'env_set' "${SET_VAR}" "${DEFAULT_VAL}"
    done < <(grep -Po "\s\Kcom\.dockstarter\.appvars\..*" "${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.labels.yml" || error "Unable to find labels for ${APPNAME}")
    run_script 'env_set' "${APPNAME}_ENABLED" true
}

test_appvars_create() {
    run_script 'env_update'
    run_script 'appvars_create' WATCHTOWER
    cat "${SCRIPTPATH}/compose/.env"
}
