#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

yml_merge() {
    run_script 'env_update'
    run_script 'appvars_create_all'
    info "Merging docker-compose.yml file."
    local RUNFILE
    RUNFILE=$(mktemp) || fatal "Failed to create temporary yml merge script."
    echo "#!/usr/bin/env bash" > "${RUNFILE}"
    {
        echo "/usr/local/bin/yq-go m \\"
        echo "\"${SCRIPTPATH}/compose/.reqs/v1.yml\" \\"
        echo "\"${SCRIPTPATH}/compose/.reqs/v2.yml\" \\"
    } >> "${RUNFILE}"
    info "Required files included."
    while IFS= read -r line; do
        local APPNAME=${line%%_ENABLED=true}
        local FILENAME=${APPNAME,,}
        if [[ -d ${SCRIPTPATH}/compose/.apps/${FILENAME}/ ]]; then
            if [[ -f ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.yml ]]; then
                local APPDEPRECATED
                APPDEPRECATED=$(run_script 'yml_get' "${APPNAME}" "services.${FILENAME}.labels[com.dockstarter.appinfo.deprecated]" || echo "false")
                if [[ ${APPDEPRECATED} == "true" ]]; then
                    warn "${APPNAME} IS DEPRECATED!"
                    warn "Please edit ${SCRIPTPATH}/compose/.env and set ${APPNAME}_ENABLED to false."
                    continue
                fi
                if [[ -f ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.${ARCH}.yml ]]; then
                    echo "\"${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.${ARCH}.yml\" \\" >> "${RUNFILE}"
                else
                    error "Failed to include ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.${ARCH}.yml file."
                    continue
                fi
                local APPNETMODE
                APPNETMODE=$(run_script 'env_get' "${APPNAME}_NETWORK_MODE")
                if [[ -z ${APPNETMODE} ]] || [[ ${APPNETMODE} == "bridge" ]]; then
                    if [[ -f ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.hostname.yml ]]; then
                        echo "\"${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.hostname.yml\" \\" >> "${RUNFILE}"
                    else
                        warn "Failed to include ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.hostname.yml file."
                    fi
                    if [[ -f ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.ports.yml ]]; then
                        echo "\"${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.ports.yml\" \\" >> "${RUNFILE}"
                    else
                        warn "Failed to include ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.ports.yml file."
                    fi
                elif [[ -n ${APPNETMODE} ]]; then
                    if [[ -f ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.netmode.yml ]]; then
                        echo "\"${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.netmode.yml\" \\" >> "${RUNFILE}"
                    else
                        warn "Failed to include ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.netmode.yml file."
                    fi
                fi
                echo "\"${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.yml\" \\" >> "${RUNFILE}"
                info "All configurations for ${APPNAME} are included."
            else
                warn "Failed to include ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.yml file."
            fi
        else
            error "Failed to include ${SCRIPTPATH}/compose/.apps/${FILENAME}/ directory."
        fi
    done < <(grep '_ENABLED=true$' < "${SCRIPTPATH}/compose/.env")
    echo "> \"${SCRIPTPATH}/compose/docker-compose.yml\"" >> "${RUNFILE}"
    run_script 'install_yq'
    info "Running compiled script to merge docker-compose.yml file."
    bash "${RUNFILE}" > /dev/null 2>&1 || fatal "Failed to run yml merge script."
    rm -f "${RUNFILE}" || warn "Failed to remove temporary yml merge script."
    info "Merging docker-compose.yml complete."
}

test_yml_merge() {
    run_script 'update_system'
    run_script 'appvars_create' PORTAINER
    cat "${SCRIPTPATH}/compose/.env"
    run_script 'yml_merge'
    cd "${SCRIPTPATH}/compose/" || fatal "Failed to change to ${SCRIPTPATH}/compose/ directory."
    docker-compose config || fatal "Failed to validate ${SCRIPTPATH}/compose/docker-compose.yml file."
    cd "${SCRIPTPATH}" || fatal "Failed to change to ${SCRIPTPATH} directory."
    run_script 'appvars_purge' PORTAINER
}
