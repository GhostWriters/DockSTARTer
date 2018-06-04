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
        for file in ./.apps/*.override.yml; do
            [[ -e ${file} ]] || break
            if [[ ${file} =~ /${FILENAME}\.override\. ]]; then
                echo "${file} \\" >> "${RUNFILE}"
            fi
        done
        for file in ./.apps/*.yml; do
            [[ -e ${file} ]] || break
            if [[ ${file} =~ /${FILENAME}\. ]]; then
                if [[ ${ARCH} == "arm64" ]]; then
                    if [[ -f ${file/\.apps\//.apps\/aarch64\/} ]]; then
                        {
                            echo "${file/\.apps\//.apps\/aarch64\/} \\"
                            echo "${file} \\"
                        } >> "${RUNFILE}"
                    fi
                    if [[ -f ${file/\.apps\//.apps\/armhf\/} ]]; then
                        {
                            echo "${file/\.apps\//.apps\/armhf\/} \\"
                            echo "${file} \\"
                        } >> "${RUNFILE}"
                    fi
                fi
                if [[ ${ARCH} == "arm" ]]; then
                    if [[ -f ${file/\.apps\//.apps\/armhf\/} ]]; then
                        {
                            echo "${file/\.apps\//.apps\/armhf\/} \\"
                            echo "${file} \\"
                        } >> "${RUNFILE}"
                    fi
                fi
                if [[ ${ARCH} == "amd64" ]]; then
                    echo "${file} \\" >> "${RUNFILE}"
                fi
            fi
        done
    fi
done <<< "${SCRIPT_VARS}"
{
    echo "> ./docker-compose.yml"
    echo "docker-compose up -d"
} >> "${RUNFILE}"

bash "${RUNFILE}"
rm "${RUNFILE}"
