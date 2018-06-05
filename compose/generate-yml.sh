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
        if [[ -f ./.apps/${FILENAME}.override.yml ]]; then
            echo "./.apps/${FILENAME}.override.yml \\" >> "${RUNFILE}"
            echo "./.apps/${FILENAME}.override.yml has been included."
        fi
        if [[ ${ARCH} == "arm64" ]]; then
            if [[ -f ./.apps/architecture/${FILENAME}.aarch64.yml ]] && [[ -f ./.apps/${FILENAME}.yml ]]; then
                echo "./.apps/architecture/${FILENAME}.aarch64.yml \\" >> "${RUNFILE}"
                echo "./.apps/${FILENAME}.yml \\" >> "${RUNFILE}"
                if [[ ${!APPNETMODE} == "bridge" ]] && [[ -f ./.apps/network/${FILENAME}.bridge.yml ]]; then
                    echo "./.apps/network/${FILENAME}.bridge.yml \\" >> "${RUNFILE}"
                elif [[ ${!APPNETMODE} == "host" ]] && [[ -f ./.apps/network/${FILENAME}.host.yml ]]; then
                    echo "./.apps/network/${FILENAME}.host.yml \\" >> "${RUNFILE}"
                fi
            elif [[ -f ./.apps/architecture/${FILENAME}.armhf.yml ]] && [[ -f ./.apps/${FILENAME}.yml ]]; then
                echo "./.apps/architecture/${FILENAME}.armhf.yml \\" >> "${RUNFILE}"
                echo "./.apps/${FILENAME}.yml \\" >> "${RUNFILE}"
                if [[ ${!APPNETMODE} == "bridge" ]] && [[ -f ./.apps/network/${FILENAME}.bridge.yml ]]; then
                    echo "./.apps/network/${FILENAME}.bridge.yml \\" >> "${RUNFILE}"
                elif [[ ${!APPNETMODE} == "host" ]] && [[ -f ./.apps/network/${FILENAME}.host.yml ]]; then
                    echo "./.apps/network/${FILENAME}.host.yml \\" >> "${RUNFILE}"
                fi
                echo "Missing aarch64 option (may not be available) falling back on armhf."
            else
                echo "Could not find ./.apps/${FILENAME}.yml and either ./.apps/architecture/${FILENAME}.aarch64.yml or ./.apps/architecture/${FILENAME}.armhf.yml"
            fi
        fi
        if [[ ${ARCH} == "arm" ]]; then
            if [[ -f ./.apps/architecture/${FILENAME}.armhf.yml ]] && [[ -f ./.apps/${FILENAME}.yml ]]; then
                echo "./.apps/architecture/${FILENAME}.armhf.yml \\" >> "${RUNFILE}"
                echo "./.apps/${FILENAME}.yml \\" >> "${RUNFILE}"
                if [[ ${!APPNETMODE} == "bridge" ]] && [[ -f ./.apps/network/${FILENAME}.bridge.yml ]]; then
                    echo "./.apps/network/${FILENAME}.bridge.yml \\" >> "${RUNFILE}"
                elif [[ ${!APPNETMODE} == "host" ]] && [[ -f ./.apps/network/${FILENAME}.host.yml ]]; then
                    echo "./.apps/network/${FILENAME}.host.yml \\" >> "${RUNFILE}"
                fi
            else
                echo "Could not find ./.apps/${FILENAME}.yml and ./.apps/architecture/${FILENAME}.armhf.yml"
            fi
        fi
        if [[ ${ARCH} == "amd64" ]]; then
            if [[ -f ./.apps/${FILENAME}.yml ]]; then
                echo "./.apps/${FILENAME}.yml \\" >> "${RUNFILE}"
                if [[ ${!APPNETMODE} == "bridge" ]] && [[ -f ./.apps/network/${FILENAME}.bridge.yml ]]; then
                    echo "./.apps/network/${FILENAME}.bridge.yml \\" >> "${RUNFILE}"
                elif [[ ${!APPNETMODE} == "host" ]] && [[ -f ./.apps/network/${FILENAME}.host.yml ]]; then
                    echo "./.apps/network/${FILENAME}.host.yml \\" >> "${RUNFILE}"
                fi
            else
                echo "Could not find ./.apps/${FILENAME}.yml"
            fi
        fi
    fi
done <<< "${SCRIPT_VARS}"
{
    echo "> ./docker-compose.yml"
    echo "docker-compose up -d"
} >> "${RUNFILE}"

bash "${RUNFILE}"
rm "${RUNFILE}"
