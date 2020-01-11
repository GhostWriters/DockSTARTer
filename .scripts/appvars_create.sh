#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

appvars_create() {
    local APPNAME=${1:-}
    APPNAME=${APPNAME^^}
    local FILENAME=${APPNAME,,}
    while IFS= read -r line; do
        local VAR_LABEL
        VAR_LABEL=$(echo "${line}" | grep --color=never -Po "^[\w]+" || true)
        if [[ -z ${VAR_LABEL} ]]; then
            continue
        fi
        local SET_VAR=${VAR_LABEL^^}

        if grep -q "^${SET_VAR}=" "${SCRIPTPATH}/compose/.env"; then
            continue
        else
            local DEFAULT_VAL
            DEFAULT_VAL=$(run_script 'yml_get' "${APPNAME}" "services.${FILENAME}.labels.com.dockstarter.appvars.${VAR_LABEL}" || true)
            echo "${SET_VAR}=" >> "${SCRIPTPATH}/compose/.env"
            run_script 'env_set' "${SET_VAR}" "${DEFAULT_VAL}"
        fi

    done < <(run_script 'yml_get' "${APPNAME}" "services.${FILENAME}.labels.com.dockstarter.appvars" || error "Unable to find labels for ${APPNAME}")
    run_script 'env_set' "${APPNAME}_ENABLED" true
}

test_appvars_create() {
    run_script 'env_update'
    run_script 'appvars_create' PORTAINER
    cat "${SCRIPTPATH}/compose/.env"
}
