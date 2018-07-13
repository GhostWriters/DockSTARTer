#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

generate_yml() {
    info "Generating docker-compose.yml file."
    local RUNFILE
    RUNFILE="${SCRIPTPATH}/compose/docker-compose.sh"
    echo "#!/bin/bash" > "${RUNFILE}"
    {
        echo "yq m \\"
        echo "${SCRIPTPATH}/compose/.reqs/v1.yml \\"
        echo "${SCRIPTPATH}/compose/.reqs/v2.yml \\"
    } >> "${RUNFILE}"
    info "Required files included."
    run_script 'env_create'
    info "Checking for enabled apps."
    while IFS= read -r line; do
        local APPNAME
        APPNAME=${line/_ENABLED=true/}
        local FILENAME
        FILENAME=${APPNAME,,}
        local APPNETMODE
        APPNETMODE=$(run_script 'env_get' "${APPNAME}_NETWORK_MODE")
        if [[ -d ${SCRIPTPATH}/compose/.apps/${FILENAME}/ ]]; then
            if [[ -f ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.override.yml ]]; then
                echo "${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.override.yml \\" >> "${RUNFILE}"
                info "${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.override.yml has been included."
            fi
            if [[ -f ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.yml ]]; then
                if [[ ${ARCH} == "arm64" ]]; then
                    if [[ -f ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.arm64.yml ]]; then
                        echo "${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.arm64.yml \\" >> "${RUNFILE}"
                    elif [[ -f ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.armhf.yml ]]; then
                        echo "${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.armhf.yml \\" >> "${RUNFILE}"
                        info "Missing arm64 option for ${APPNAME} (may not be available) falling back on armhf."
                    else
                        error "Could not find ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.arm64.yml file or ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.armhf.yml file."
                        continue
                    fi
                fi
                if [[ ${ARCH} == "armhf" ]]; then
                    if [[ -f ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.armhf.yml ]]; then
                        echo "${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.armhf.yml \\" >> "${RUNFILE}"
                    else
                        error "Could not find ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.armhf.yml file."
                        continue
                    fi
                fi
                if [[ -z ${APPNETMODE} ]] || [[ ${APPNETMODE} == "bridge" ]]; then
                    if [[ -f ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.ports.yml ]]; then
                        echo "${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.ports.yml \\" >> "${RUNFILE}"
                        info "${APPNAME}_NETWORK_MODE supports port mapping. Ports will be included."
                    else
                        warning "Could not find ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.ports.yml file."
                    fi
                fi
                if [[ -n ${APPNETMODE} ]]; then
                    if [[ -f ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.netmode.yml ]]; then
                        echo "${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.netmode.yml \\" >> "${RUNFILE}"
                        info "${APPNAME}_NETWORK_MODE is set to ${APPNETMODE}."
                    else
                        warning "Could not find ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.netmode.yml file."
                    fi
                fi
                echo "${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.yml \\" >> "${RUNFILE}"
                info "All configurations for ${APPNAME} are included."
            else
                warning "Could not find ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.yml file."
            fi
        else
            error "Could not find ${SCRIPTPATH}/compose/.apps/${FILENAME}/ directory."
        fi
    done < <(grep '_ENABLED=true' < "${SCRIPTPATH}/compose/.env")
    echo "> ${SCRIPTPATH}/compose/docker-compose.yml" >> "${RUNFILE}"
    run_script 'install_yq'
    bash "${RUNFILE}"
    info "Merging docker-compose.yml complete."
    trap 'rm -f "${SCRIPTPATH}/compose/docker-compose.sh"' EXIT
}
