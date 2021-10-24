#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

yml_merge() {
    run_script 'env_update'
    run_script 'appvars_create_all'
    info "Compiling enabled templates to merge docker-compose.yml file."
    local ENABLED_TEMPLATES
    ENABLED_TEMPLATES=$(mktemp -d) || fatal "Failed to create temporary directory for enabled templates.\nFailing command: ${F[C]}mktemp -d"
    cp "${SCRIPTPATH}/compose/.reqs/r1.yml" "${ENABLED_TEMPLATES}" || fatal "Failed to copy required files to temporary directory for enabled templates.\nFailing command: ${F[C]}cp \"${SCRIPTPATH}/compose/.reqs/r1.yml\" \"${ENABLED_TEMPLATES}\""
    cp "${SCRIPTPATH}/compose/.reqs/r2.yml" "${ENABLED_TEMPLATES}" || fatal "Failed to copy required files to temporary directory for enabled templates.\nFailing command: ${F[C]}cp \"${SCRIPTPATH}/compose/.reqs/r2.yml\" \"${ENABLED_TEMPLATES}\""
    info "Required files included."
    notice "Adding compose configurations for enabled apps. Please be patient, this can take a while."
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
                cp "${APPTEMPLATES}/${FILENAME}.${ARCH}.yml" "${ENABLED_TEMPLATES}" || fatal "Failed to copy required files to temporary directory for enabled templates.\nFailing command: ${F[C]}cp \"${APPTEMPLATES}/${FILENAME}.${ARCH}.yml\" \"${ENABLED_TEMPLATES}\""
                local APPNETMODE
                APPNETMODE=$(run_script 'env_get' "${APPNAME}_NETWORK_MODE")
                if [[ -z ${APPNETMODE} ]] || [[ ${APPNETMODE} == "bridge" ]]; then
                    if [[ -f ${APPTEMPLATES}/${FILENAME}.hostname.yml ]]; then
                        cp "${APPTEMPLATES}/${FILENAME}.hostname.yml" "${ENABLED_TEMPLATES}" || fatal "Failed to copy required files to temporary directory for enabled templates.\nFailing command: ${F[C]}cp \"${APPTEMPLATES}/${FILENAME}.hostname.yml\" \"${ENABLED_TEMPLATES}\""
                    else
                        info "${APPTEMPLATES}/${FILENAME}.hostname.yml does not exist."
                    fi
                    if [[ -f ${APPTEMPLATES}/${FILENAME}.ports.yml ]]; then
                        cp "${APPTEMPLATES}/${FILENAME}.ports.yml" "${ENABLED_TEMPLATES}" || fatal "Failed to copy required files to temporary directory for enabled templates.\nFailing command: ${F[C]}cp \"${APPTEMPLATES}/${FILENAME}.ports.yml\" \"${ENABLED_TEMPLATES}\""
                    else
                        info "${APPTEMPLATES}/${FILENAME}.ports.yml does not exist."
                    fi
                elif [[ -n ${APPNETMODE} ]]; then
                    if [[ -f ${APPTEMPLATES}/${FILENAME}.netmode.yml ]]; then
                        cp "${APPTEMPLATES}/${FILENAME}.netmode.yml" "${ENABLED_TEMPLATES}" || fatal "Failed to copy required files to temporary directory for enabled templates.\nFailing command: ${F[C]}cp \"${APPTEMPLATES}/${FILENAME}.netmode.yml\" \"${ENABLED_TEMPLATES}\""
                    else
                        info "${APPTEMPLATES}/${FILENAME}.netmode.yml does not exist."
                    fi
                fi
                cp "${APPTEMPLATES}/${FILENAME}.yml" "${ENABLED_TEMPLATES}" || fatal "Failed to copy required files to temporary directory for enabled templates.\nFailing command: ${F[C]}cp \"${APPTEMPLATES}/${FILENAME}.yml\" \"${ENABLED_TEMPLATES}\""
                info "All configurations for ${APPNAME} are included."
            else
                warn "${APPTEMPLATES}/${FILENAME}.yml does not exist."
            fi
        else
            error "${APPTEMPLATES}/ does not exist."
        fi
    done < <(grep --color=never -P '_ENABLED='"'"'?true'"'"'?$' "${COMPOSE_ENV}")
    info "Running yq to create docker-compose.yml file from enabled templates."
    export YQ_OPTIONS="${YQ_OPTIONS:-} -v ${ENABLED_TEMPLATES}:${ENABLED_TEMPLATES}"
    run_script 'run_yq' "${YML_ARGS:-} -y -s 'reduce .[] as \$item ({}; . * \$item) | del(.version)' ${ENABLED_TEMPLATES}/*.yml > ${SCRIPTPATH}/compose/docker-compose.yml"
    rm -rf "${ENABLED_TEMPLATES}" || warn "Failed to remove temporary directory for enabled templates."
    info "Merging docker-compose.yml complete."
}

test_yml_merge() {
    run_script 'appvars_create' WATCHTOWER
    cat "${COMPOSE_ENV}"
    run_script 'yml_merge'
    cd "${SCRIPTPATH}/compose/" || fatal "Failed to change directory.\nFailing command: ${F[C]}cd \"${SCRIPTPATH}/compose/\""
    run_script 'run_compose' "config"
    cd "${SCRIPTPATH}" || fatal "Failed to change directory.\nFailing command: ${F[C]}cd \"${SCRIPTPATH}\""
    run_script 'appvars_purge' WATCHTOWER
}
