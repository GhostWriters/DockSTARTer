#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

appvar_create() {
    local APPNAME=${1:-}
    local FILENAME=${APPNAME,,}
    while IFS= read -r line; do
        local VAR_LABEL
        VAR_LABEL=$(echo "${line}" | grep --color=never -Po "^com\.dockstarter\.\K[\w]+")
        local SET_VAR=${VAR_LABEL^^}

        if grep --color=never "^${SET_VAR}=" "${SCRIPTPATH}/compose/.env"; then
            continue
        elif [[ ${SET_VAR} == "${APPNAME}_NICENAME" ]]; then
            continue
        elif [[ ${SET_VAR} == "${APPNAME}_DESCRIPTION" ]]; then
            continue
        else
            local DEFAULT_VAL
            DEFAULT_VAL=$(run_script 'yml_get' "${APPNAME}" "services.${FILENAME}.labels[com.dockstarter.${VAR_LABEL}]" || true)
            echo "${SET_VAR}=" >> "${SCRIPTPATH}/compose/.env"
            run_script 'env_set' "${SET_VAR}" "${DEFAULT_VAL}"
        fi

    done < <(run_script 'yml_get' "${APPNAME}" "services.${FILENAME}.labels" || true)
}

test_appvar_create() {
    run_script 'appvar_create' WATCHTOWER
    error "TESTS ARE NOT YET CREATED."
}
