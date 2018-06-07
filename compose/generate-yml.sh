#!/bin/bash

# # Common
source "../scripts/common.sh"

# # Environment
VARS="$(set -o posix ; set)"
source "./.env"
SCRIPT_VARS="$(grep -vFe "${VARS}" <<<"$(set -o posix ; set)" | grep -v ^VARS=)"
unset VARS

RUNFILE="./docker-compose.sh"
echo "#!/bin/bash" > "${RUNFILE}"
{
    echo "yq m \\"
    echo "./.reqs/v1.yml \\"
    echo "./.reqs/v2.yml \\"
} >> "${RUNFILE}"
while read -r line || [ -n "${line}" ]; do
    if [[ ${line} ==  *"_ENABLED=true" ]]; then
        APPNAME=${line/_ENABLED=true/}
        FILENAME=${APPNAME,,}
        APPNETMODE="${APPNAME}_NETWORK_MODE"
        if [[ -d ./.apps/${FILENAME}/ ]]; then
            if [[ -f ./.apps/${FILENAME}/${FILENAME}.override.yml ]]; then
                echo "./.apps/${FILENAME}/${FILENAME}.override.yml \\" >> "${RUNFILE}"
                echo "./.apps/${FILENAME}/${FILENAME}.override.yml has been included."
            fi
            if [[ -f ./.apps/${FILENAME}/${FILENAME}.yml ]]; then
                if [[ ${ARCH} == "arm64" ]]; then
                    if [[ -f ./.apps/${FILENAME}/${FILENAME}.aarch64.yml ]]; then
                        echo "./.apps/${FILENAME}/${FILENAME}.aarch64.yml \\" >> "${RUNFILE}"
                    elif [[ -f ./.apps/${FILENAME}/${FILENAME}.armhf.yml ]]; then
                        echo "./.apps/${FILENAME}/${FILENAME}.armhf.yml \\" >> "${RUNFILE}"
                        echo "Missing aarch64 option for ${APPNAME} (may not be available) falling back on armhf."
                    else
                        echo "Could not find ./.apps/${FILENAME}/${FILENAME}.aarch64.yml file or ./.apps/${FILENAME}/${FILENAME}.armhf.yml file."
                        continue
                    fi
                fi
                if [[ ${ARCH} == "arm" ]]; then
                    if [[ -f ./.apps/${FILENAME}/${FILENAME}.armhf.yml ]]; then
                        echo "./.apps/${FILENAME}/${FILENAME}.armhf.yml \\" >> "${RUNFILE}"
                    else
                        echo "Could not find ./.apps/${FILENAME}/${FILENAME}.armhf.yml file."
                        continue
                    fi
                fi
                if [[ ${!APPNETMODE} == "bridge" ]] && [[ -f ./.apps/${FILENAME}/${FILENAME}.bridge.yml ]]; then
                    echo "./.apps/${FILENAME}/${FILENAME}.bridge.yml \\" >> "${RUNFILE}"
                elif [[ ${!APPNETMODE} == "host" ]] && [[ -f ./.apps/${FILENAME}/${FILENAME}.host.yml ]]; then
                    echo "./.apps/${FILENAME}/${FILENAME}.host.yml \\" >> "${RUNFILE}"
                else
                    echo "Could not find ./.apps/${FILENAME}/${FILENAME}.bridge.yml file or ./.apps/${FILENAME}/${FILENAME}.host.yml file."
                fi
                echo "./.apps/${FILENAME}/${FILENAME}.yml \\" >> "${RUNFILE}"
            else
                echo "Could not find ./.apps/${FILENAME}/${FILENAME}.yml file."
            fi
        else
            echo "Could not find ./.apps/${FILENAME}/ directory."
        fi
    fi
done <<< "${SCRIPT_VARS}"
{
    echo "> ./docker-compose.yml"
    echo "docker-compose up -d"
} >> "${RUNFILE}"

bash "${RUNFILE}"
rm "${RUNFILE}"
