#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

yml_merge() {
    run_script 'env_update'
    run_script 'appvars_create_all'
    info "Compiling arguments to merge docker-compose.yml file."
    local YML_ARGS
    YML_ARGS="${YML_ARGS:-} -y -s 'reduce .[] as \$item ({}; . * \$item) | del(.version)'"
    YML_ARGS="${YML_ARGS:-} \"${SCRIPTPATH}/compose/.reqs/r1.yml\""
    YML_ARGS="${YML_ARGS:-} \"${SCRIPTPATH}/compose/.reqs/r2.yml\""
    info "Required files included."
    notice "Adding compose configurations for enabled apps. Please be patient, this can take a while."
    while IFS= read -r line; do
        local APPNAME=${line%%_ENABLED=true}
        local FILENAME=${APPNAME,,}
        if [[ -d ${SCRIPTPATH}/compose/.apps/${FILENAME}/ ]]; then
            if [[ -f ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.yml ]]; then
                local APPDEPRECATED
                APPDEPRECATED=$(grep --color=never -Po "\scom\.dockstarter\.appinfo\.deprecated: \K.*" "${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.labels.yml" | sed -E 's/^([^"].*[^"])$/"\1"/' | xargs || echo "false")
                if [[ ${APPDEPRECATED} == "true" ]]; then
                    warn "${APPNAME} IS DEPRECATED!"
                    warn "Please edit ${SCRIPTPATH}/compose/.env and set ${APPNAME}_ENABLED to false."
                    continue
                fi
                if [[ ! -f ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.${ARCH}.yml ]]; then
                    error "${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.${ARCH}.yml does not exist."
                    continue
                fi
                YML_ARGS="${YML_ARGS:-} \"${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.${ARCH}.yml\""
                local APPNETMODE
                APPNETMODE=$(run_script 'env_get' "${APPNAME}_NETWORK_MODE")
                if [[ -z ${APPNETMODE} ]] || [[ ${APPNETMODE} == "bridge" ]]; then
                    if [[ -f ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.hostname.yml ]]; then
                        YML_ARGS="${YML_ARGS:-} \"${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.hostname.yml\""
                    else
                        info "${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.hostname.yml does not exist."
                    fi
                    if [[ -f ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.ports.yml ]]; then
                        YML_ARGS="${YML_ARGS:-} \"${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.ports.yml\""
                    else
                        info "${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.ports.yml does not exist."
                    fi
                elif [[ -n ${APPNETMODE} ]]; then
                    if [[ -f ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.netmode.yml ]]; then
                        YML_ARGS="${YML_ARGS:-} \"${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.netmode.yml\""
                    else
                        info "${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.netmode.yml does not exist."
                    fi
                fi
                YML_ARGS="${YML_ARGS:-} \"${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.yml\""
                info "All configurations for ${APPNAME} are included."
            else
                warn "${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.yml does not exist."
            fi
        else
            error "${SCRIPTPATH}/compose/.apps/${FILENAME}/ does not exist."
        fi
    done < <(grep '_ENABLED=true$' < "${SCRIPTPATH}/compose/.env")
    YML_ARGS="${YML_ARGS:-} > \"${SCRIPTPATH}/compose/docker-compose.yml\""
    info "Running compiled arguments to merge docker-compose.yml file."
    export YQ_OPTIONS="${YQ_OPTIONS:-} -v ${SCRIPTPATH}:${SCRIPTPATH}"
    run_script 'run_yq' "${YML_ARGS}"
    info "Merging docker-compose.yml complete."
}

test_yml_merge() {
    run_script 'appvars_create' WATCHTOWER
    cat "${SCRIPTPATH}/compose/.env"
    run_script 'yml_merge'
    cd "${SCRIPTPATH}/compose/" || fatal "Failed to change directory.\nFailing command: ${F[C]}cd \"${SCRIPTPATH}/compose/\""
    run_script 'run_compose' "config"
    cd "${SCRIPTPATH}" || fatal "Failed to change directory.\nFailing command: ${F[C]}cd \"${SCRIPTPATH}\""
    run_script 'appvars_purge' WATCHTOWER
}
