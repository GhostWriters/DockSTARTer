#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

run_generate_full() {
    if [[ ${CI:-} == true ]] && [[ ${TRAVIS:-} == true ]] && [[ ${TRAVIS_SECURE_ENV_VARS} == true ]]; then
        service mysql stop
    fi
    run_script 'env_update'
    while IFS= read -r line; do
        local APPNAME
        APPNAME=${line/_ENABLED=*/}
        sed -i 's/_ENABLED=true/_ENABLED=false/' "${SCRIPTPATH}/compose/.env"
        run_script 'env_set' "${APPNAME}_ENABLED" true
        run_test 'run_generate_slim'
    done < <(grep '_ENABLED=' < "${SCRIPTPATH}/compose/.env")
}
