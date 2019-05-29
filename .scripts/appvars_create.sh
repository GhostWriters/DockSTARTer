#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

appvars_create() {
    local APPNAME=${1:-}
    local FILENAME=${APPNAME,,}
    while IFS= read -r line; do
        local VAR_LABEL
        VAR_LABEL=$(echo "${line}" | grep --color=never -Po "^com\.dockstarter\.appvars\K[\w]+" || true)
        if [[ -z ${VAR_LABEL} ]]; then
            continue
        fi
        local SET_VAR=${VAR_LABEL^^}

        if grep --color=never "^${SET_VAR}=" "${SCRIPTPATH}/compose/.env"; then
            continue
        else
            local DEFAULT_VAL
            DEFAULT_VAL=$(run_script 'yml_get' "${APPNAME}" "services.${FILENAME}.labels[com.dockstarter.appvars.${VAR_LABEL}]" || true)
            echo "${SET_VAR}=" >> "${SCRIPTPATH}/compose/.env"
            run_script 'env_set' "${SET_VAR}" "${DEFAULT_VAL}"
        fi

    done < <(run_script 'yml_get' "${APPNAME}" "services.${FILENAME}.labels" || true)
}

test_appvars_create() {
    run_script 'appvars_create' WATCHTOWER
    error "TESTS ARE NOT YET CREATED."
}
