#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

yml_merge() {
    run_script 'appvars_create_all'
    run_script 'env_update'
    local COMPOSE_FILE=""
    notice "Adding enabled app templates to merge docker-compose.yml. Please be patient, this can take a while."
    while IFS= read -r line; do
        local APPNAME=${line%%_ENABLED=*}
        local FILENAME=${APPNAME,,}
        local APPTEMPLATES="${SCRIPTPATH}/compose/.apps/${FILENAME}"
        if [[ -d ${APPTEMPLATES}/ ]]; then
            if [[ -f ${APPTEMPLATES}/${FILENAME}.yml ]]; then
                local APPDEPRECATED
                APPDEPRECATED=$(grep --color=never -Po "\scom\.dockstarter\.appinfo\.deprecated: \K.*" "${APPTEMPLATES}/${FILENAME}.labels.yml" | sed -E 's/^([^"].*[^"])$/"\1"/' | xargs || echo false)
                if [[ ${APPDEPRECATED} == true ]]; then
                    warn "${APPNAME} IS DEPRECATED!"
                    warn "Please edit ${COMPOSE_ENV} and set ${APPNAME}_ENABLED to false."
                    continue
                fi
                if [[ ! -f ${APPTEMPLATES}/${FILENAME}.${ARCH}.yml ]]; then
                    error "${APPTEMPLATES}/${FILENAME}.${ARCH}.yml does not exist."
                    continue
                fi
                COMPOSE_FILE="${COMPOSE_FILE}:${APPTEMPLATES}/${FILENAME}.${ARCH}.yml"
                local APPNETMODE
                APPNETMODE=$(run_script 'env_get' "${APPNAME}_NETWORK_MODE")
                if [[ -z ${APPNETMODE} ]] || [[ ${APPNETMODE} == "bridge" ]]; then
                    if [[ -f ${APPTEMPLATES}/${FILENAME}.hostname.yml ]]; then
                        COMPOSE_FILE="${COMPOSE_FILE}:${APPTEMPLATES}/${FILENAME}.hostname.yml"
                    else
                        info "${APPTEMPLATES}/${FILENAME}.hostname.yml does not exist."
                    fi
                    if [[ -f ${APPTEMPLATES}/${FILENAME}.ports.yml ]]; then
                        COMPOSE_FILE="${COMPOSE_FILE}:${APPTEMPLATES}/${FILENAME}.ports.yml"
                    else
                        info "${APPTEMPLATES}/${FILENAME}.ports.yml does not exist."
                    fi
                elif [[ -n ${APPNETMODE} ]]; then
                    if [[ -f ${APPTEMPLATES}/${FILENAME}.netmode.yml ]]; then
                        COMPOSE_FILE="${COMPOSE_FILE}:${APPTEMPLATES}/${FILENAME}.netmode.yml"
                    else
                        info "${APPTEMPLATES}/${FILENAME}.netmode.yml does not exist."
                    fi
                fi
                COMPOSE_FILE="${COMPOSE_FILE}:${APPTEMPLATES}/${FILENAME}.yml"
                info "All configurations for ${APPNAME} are included."
            else
                warn "${APPTEMPLATES}/${FILENAME}.yml does not exist."
            fi
        else
            error "${APPTEMPLATES}/ does not exist."
        fi
    done < <(grep --color=never -P '_ENABLED='"'"'?true'"'"'?$' "${COMPOSE_ENV}")
    if [[ -z ${COMPOSE_FILE} ]]; then
        fatal "No enabled apps found."
    fi
    info "Running compose config to create docker-compose.yml file from enabled templates."
    export COMPOSE_FILE="${COMPOSE_FILE#:}"
    eval "docker compose --project-directory ${SCRIPTPATH}/compose/ config > ${SCRIPTPATH}/compose/docker-compose.yml" || fatal "Failed to output compose config.\nFailing command: ${F[C]}docker compose --project-directory ${SCRIPTPATH}/compose/ config > \"${SCRIPTPATH}/compose/docker-compose.yml\""
    info "Merging docker-compose.yml complete."
}

test_yml_merge() {
    run_script 'appvars_create' WATCHTOWER
    cat "${COMPOSE_ENV}"
    run_script 'yml_merge'
    eval "docker compose --project-directory ${SCRIPTPATH}/compose/ config" || fatal "Failed to display compose config.\nFailing command: ${F[C]}docker compose --project-directory ${SCRIPTPATH}/compose/ config"
    run_script 'appvars_purge' WATCHTOWER
}
