#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

yml_merge() {
    commands_yml_merge
}

commands_yml_merge() {
    run_script 'appvars_create_all'
    local COMPOSE_FILE=""
    notice "Adding enabled app templates to merge docker-compose.yml. Please be patient, this can take a while."
    local ENABLED_APPS
    ENABLED_APPS=$(run_script 'app_list_enabled')
    for APPNAME in ${ENABLED_APPS-}; do
        local appname=${APPNAME,,}
        local AppName
        AppName=$(run_script 'app_nicename' "${APPNAME}")
        local APP_FOLDER="${TEMPLATES_FOLDER}/${appname}"
        if [[ -d ${APP_FOLDER}/ ]]; then
            if [[ -f ${APP_FOLDER}/${appname}.yml ]]; then
                if run_script 'app_is_depreciated' "${APPNAME}"; then
                    warn "${AppName} IS DEPRECATED!"
                    warn "Please edit ${COMPOSE_ENV} and set ${APPNAME}__ENABLED to false."
                    continue
                fi
                if [[ ! -f ${APP_FOLDER}/${appname}.${ARCH}.yml ]]; then
                    error "${APP_FOLDER}/${appname}.${ARCH}.yml does not exist."
                    continue
                fi
                COMPOSE_FILE="${COMPOSE_FILE}:${APP_FOLDER}/${appname}.${ARCH}.yml"
                local APPNETMODE
                APPNETMODE=$(run_script 'env_get' "${APPNAME}__NETWORK_MODE")
                if [[ -z ${APPNETMODE} ]] || [[ ${APPNETMODE} == "bridge" ]]; then
                    if [[ -f ${APP_FOLDER}/${appname}.hostname.yml ]]; then
                        COMPOSE_FILE="${COMPOSE_FILE}:${APP_FOLDER}/${appname}.hostname.yml"
                    else
                        info "${APP_FOLDER}/${appname}.hostname.yml does not exist."
                    fi
                    if [[ -f ${APP_FOLDER}/${appname}.ports.yml ]]; then
                        COMPOSE_FILE="${COMPOSE_FILE}:${APP_FOLDER}/${appname}.ports.yml"
                    else
                        info "${APP_FOLDER}/${appname}.ports.yml does not exist."
                    fi
                elif [[ -n ${APPNETMODE} ]]; then
                    if [[ -f ${APP_FOLDER}/${appname}.netmode.yml ]]; then
                        COMPOSE_FILE="${COMPOSE_FILE}:${APP_FOLDER}/${appname}.netmode.yml"
                    else
                        info "${APP_FOLDER}/${appname}.netmode.yml does not exist."
                    fi
                fi
                COMPOSE_FILE="${COMPOSE_FILE}:${APP_FOLDER}/${appname}.yml"
                info "All configurations for ${AppName} are included."
            else
                warn "${APP_FOLDER}/${appname}.yml does not exist."
            fi
            run_script 'appfolders_create' "${APPNAME}"
        else
            error "${APP_FOLDER}/ does not exist."
        fi
    done
    if [[ -z ${COMPOSE_FILE} ]]; then
        fatal "No enabled apps found."
    fi
    info "Running compose config to create docker-compose.yml file from enabled templates."
    export COMPOSE_FILE="${COMPOSE_FILE#:}"
    eval "docker compose --project-directory ${COMPOSE_FOLDER}/ config > ${COMPOSE_FOLDER}/docker-compose.yml" || fatal "Failed to output compose config.\nFailing command: ${F[C]}docker compose --project-directory ${COMPOSE_FOLDER}/ config > \"${COMPOSE_FOLDER}/docker-compose.yml\""
    info "Merging docker-compose.yml complete."
}
test_yml_merge() {
    run_script 'appvars_create' WATCHTOWER
    cat "${COMPOSE_ENV}"
    run_script 'yml_merge'
    eval "docker compose --project-directory ${COMPOSE_FOLDER}/ config" || fatal "Failed to display compose config.\nFailing command: ${F[C]}docker compose --project-directory ${COMPOSE_FOLDER}/ config"
    run_script 'appvars_purge' WATCHTOWER
}
