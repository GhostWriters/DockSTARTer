#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

appvars_create_all() {
    if grep -q '_ENABLED=true$' "${SCRIPTPATH}/compose/.env"; then
        while IFS= read -r line; do
            local APPNAME=${line%%_ENABLED=true}
            run_script 'appvars_create' "${APPNAME}"
        done < <(grep '_ENABLED=true$' < "${SCRIPTPATH}/compose/.env")
    else
        info "${SCRIPTPATH}/compose/.env does not contain any disabled apps."
    fi
}

test_appvars_create_all() {
    run_script 'env_update'
    run_script 'appvars_create_all'
    cat "${SCRIPTPATH}/compose/.env"
}
