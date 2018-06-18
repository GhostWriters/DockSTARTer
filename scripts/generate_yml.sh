#!/bin/bash

generate_yml () {
    local ENV_VARS
    ENV_VARS="$(run_script 'get_env';)"
    local RUNFILE
    RUNFILE="${SCRIPTPATH}/compose/docker-compose.sh"
    echo "#!/bin/bash" > "${RUNFILE}"
    {
        echo "yq m \\"
        echo "${SCRIPTPATH}/compose/.reqs/v1.yml \\"
        echo "${SCRIPTPATH}/compose/.reqs/v2.yml \\"
    } >> "${RUNFILE}"
    echo "${ENV_VARS}" | while read -r line || [ -n "${line}" ]; do
        if [[ ${line} ==  *"_ENABLED=true" ]]; then
            local APPNAME
            APPNAME=${line/_ENABLED=true/}
            local FILENAME
            FILENAME=${APPNAME,,}
            local APPNETMODE
            APPNETMODE="${APPNAME}_NETWORK_MODE"
            if [[ -d ${SCRIPTPATH}/compose/.apps/${FILENAME}/ ]]; then
                if [[ -f ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.override.yml ]]; then
                    echo "${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.override.yml \\" >> "${RUNFILE}"
                    echo "${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.override.yml has been included."
                fi
                if [[ -f ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.yml ]]; then
                    if [[ ${ARCH} == "arm64" ]]; then
                        if [[ -f ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.arm64.yml ]]; then
                            echo "${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.arm64.yml \\" >> "${RUNFILE}"
                        elif [[ -f ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.armhf.yml ]]; then
                            echo "${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.armhf.yml \\" >> "${RUNFILE}"
                            echo "Missing arm64 option for ${APPNAME} (may not be available) falling back on armhf."
                        else
                            echo "Could not find ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.arm64.yml file or ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.armhf.yml file."
                            continue
                        fi
                    fi
                    if [[ ${ARCH} == "armhf" ]]; then
                        if [[ -f ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.armhf.yml ]]; then
                            echo "${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.armhf.yml \\" >> "${RUNFILE}"
                        else
                            echo "Could not find ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.armhf.yml file."
                            continue
                        fi
                    fi
                    if [[ ${!APPNETMODE} == "bridge" ]]; then
                        if [[ -f ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.${!APPNETMODE}.yml ]]; then
                            echo "${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.${!APPNETMODE}.yml \\" >> "${RUNFILE}"
                        else
                            echo "Could not find ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.${!APPNETMODE}.yml file."
                        fi
                    fi
                    echo "${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.yml \\" >> "${RUNFILE}"
                else
                    echo "Could not find ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.yml file."
                fi
            else
                echo "Could not find ${SCRIPTPATH}/compose/.apps/${FILENAME}/ directory."
            fi
        fi
    done
    echo "> ${SCRIPTPATH}/compose/docker-compose.yml" >> "${RUNFILE}"
    sh "${RUNFILE}"
    rm "${RUNFILE}"
}
