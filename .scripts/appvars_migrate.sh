#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

appvars_migrate() {
    local APPNAME=${1-}
    APPNAME=${APPNAME^^}
    while IFS= read -r line; do
        local VAR_VAL=${line}
        local SET_VAR=${VAR_VAL%%=*}
        local REST_VAR=${SET_VAR#*_}
        local NEW_VAR="${SET_VAR}"
        case "${SET_VAR}" in
            *DIR | *DIR_*)
                NEW_VAR="${APPNAME}_VOLUME_${REST_VAR}"
                ;;
            *)
                NEW_VAR="${APPNAME}_ENVIRONMENT_${REST_VAR}"
                ;;
        esac
        if [[ ${SET_VAR} != "${NEW_VAR}" ]]; then
            run_script 'env_rename' "${SET_VAR}" "${NEW_VAR}"
        fi
    done < <(grep --color=never -P "\b${APPNAME}_(?!(ENABLED|ENVIRONMENT_|NETWORK_MODE|PORT_|RESTART|TAG|VOLUME_))" "${COMPOSE_ENV}")

}

test_appvars_migrate() {
    # run_script 'appvars_migrate'
    warn "CI does not test appvars_migrate."
}
