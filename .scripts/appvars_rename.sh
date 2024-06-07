#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

appvars_rename() {
    local FROMAPP=${1-}
    local TOAPP=${2-}
    local FROMAPP_ENABLED
    FROMAPP_ENABLED=$(run_script 'env_get' "${FROMAPP^^}_ENABLED")
    local TOAPP_ENABLED
    TOAPP_ENABLED=$(run_script 'env_get' "${TOAPP^^}_ENABLED")
    if [[ ${FROMAPP_ENABLED} == true ]] && [[ ${TOAPP_ENABLED} != true ]]; then
        notice "Migrating from ${FROMAPP^^} to ${TOAPP^^}."
        docker stop "${FROMAPP,,}" || warn "Failed to stop ${FROMAPP,,} container.\nFailing command: ${F[C]}docker stop ${FROMAPP,,}"
        notice "Moving config folder."
        local DOCKER_VOLUME_CONFIG
        DOCKER_VOLUME_CONFIG=$(run_script 'env_get' DOCKER_VOLUME_CONFIG)
        mv "${DOCKER_VOLUME_CONFIG}/${FROMAPP,,}" "${DOCKER_VOLUME_CONFIG}/${TOAPP,,}" || warn "Failed to move folder.\nFailing command: ${F[C]}mv \"${DOCKER_VOLUME_CONFIG}/${FROMAPP,,}\" \"${DOCKER_VOLUME_CONFIG}/${TOAPP,,}\""
        notice "Migrating vars."
        sed -i "s/^\s*${FROMAPP^^}_/${TOAPP^^}_/" "${COMPOSE_ENV}" || fatal "Failed to migrate vars from ${FROMAPP^^}_ to ${TOAPP^^}_\nFailing command: ${F[C]}sed -i \"s/^\\s*${FROMAPP^^}_/${TOAPP^^}_/\" \"${COMPOSE_ENV}\""
        run_script 'appvars_create' "${TOAPP^^}"
        notice "Completed migrating from ${FROMAPP^^} to ${TOAPP^^}. Run ${F[C]}ds -c${NC} to create the new container."
    fi
}

test_appvars_rename() {
    # run_script 'appvars_rename'
    warn "CI does not test appvars_rename."
}
