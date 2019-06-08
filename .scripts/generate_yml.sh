#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

generate_yml() {
    run_script 'env_update'
    info "Generating docker-compose.yml file."
    local RUNFILE
    RUNFILE="$(mktemp)"
    echo "#!/usr/bin/env bash" > "${RUNFILE}"
    {
        echo '/usr/local/bin/yq-go m '\\
        echo "${SCRIPTPATH}/compose/.reqs/v1.yml \\"
        echo "${SCRIPTPATH}/compose/.reqs/v2.yml \\"
    } >> "${RUNFILE}"
    info "Required files included."
    while IFS= read -r line; do
        local APPNAME=${line%%_ENABLED=true}
        local FILENAME=${APPNAME,,}
        if [[ -d ${SCRIPTPATH}/compose/.apps/${FILENAME}/ ]]; then
            if [[ -f ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.yml ]]; then
                if [[ -f ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.${ARCH}.yml ]]; then
                    echo "${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.${ARCH}.yml \\" >> "${RUNFILE}"
                else
                    error "Failed to include ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.${ARCH}.yml file."
                    continue
                fi
                local APPNETMODE
                APPNETMODE=$(run_script 'env_get' "${APPNAME}_NETWORK_MODE")
                if [[ -z ${APPNETMODE} ]] || [[ ${APPNETMODE} == "bridge" ]]; then
                    if [[ -f ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.hostname.yml ]]; then
                        echo "${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.hostname.yml \\" >> "${RUNFILE}"
                    else
                        warning "Failed to include ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.hostname.yml file."
                    fi
                    if [[ -f ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.ports.yml ]]; then
                        echo "${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.ports.yml \\" >> "${RUNFILE}"
                    else
                        warning "Failed to include ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.ports.yml file."
                    fi
                elif [[ -n ${APPNETMODE} ]]; then
                    if [[ -f ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.netmode.yml ]]; then
                        echo "${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.netmode.yml \\" >> "${RUNFILE}"
                    else
                        warning "Failed to include ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.netmode.yml file."
                    fi
                fi
                echo "${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.yml \\" >> "${RUNFILE}"
                info "All configurations for ${APPNAME} are included."
            else
                warning "Failed to include ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.yml file."
            fi
        else
            error "Failed to include ${SCRIPTPATH}/compose/.apps/${FILENAME}/ directory."
        fi
    done < <(grep '_ENABLED=true$' < "${SCRIPTPATH}/compose/.env")
    echo "> ${SCRIPTPATH}/compose/docker-compose.yml" >> "${RUNFILE}"
    run_script 'install_yq'
    bash "${RUNFILE}" > /dev/null 2>&1 || fatal "Failed to run generator."
    rm -f "${RUNFILE}" || warning "Temporary yml generator file could not be removed."
    info "Merging docker-compose.yml complete."
}

test_generate_yml() {
    run_script 'update_system'
    run_script 'generate_yml'
    cd "${SCRIPTPATH}/compose/" || fatal "Failed to change to ${SCRIPTPATH}/compose/ directory."
    docker-compose config || fatal "Failed to validate ${SCRIPTPATH}/compose/docker-compose.yml file."
    cd "${SCRIPTPATH}" || fatal "Failed to change to ${SCRIPTPATH} directory."
}
