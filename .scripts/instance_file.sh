#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

instance_file() {
    # instance_file AppName FileSuffix
    # Returns the filename of a file in the instance folder for the app specified
    #
    # instance_file "radarr" ".labels.yml" will return a string similar to "/home/user/.docker/compose/.instances/radarr/radarr.labels.yml"
    # If the file does not exist, it is created from the matching file in the "templates" folder.

    local AppName=${1:-}
    local FileSuffix=${2:-}
    local appname=${AppName,,}

    local baseapp instance InstanceFolder InstanceFile
    baseapp="$(run_script 'appname_to_baseappname' "${appname}")"
    instance="$(run_script 'appname_to_instancename' "${appname}")"
    
    InstanceFolder="$(run_script 'instance_folder' "${appname}")"
    if [[ -z ${InstanceFolder} ]]; then
        return
    fi
    InstanceFile="${InstanceFolder}/${appname}${FileSuffix}"
    if [[ ! -f ${InstanceFile} ]]; then
        local TemplateFile="${TEMPLATES_FOLDER}/${baseapp}/${baseapp}${FileSuffix}"
        if [[ ! -f ${TemplateFile} ]]; then
            warn "${TemplateFile} does not exist."
            return
        fi
        local __INSTANCE __Instance __instance
        if [[ -n ${instance} ]]; then
            __INSTANCE="__${instance^^}"
            __Instance="__${instance^}"
            __instance="__${instance,,}"
        fi
        sed -e "s/<__INSTANCE>/${__INSTANCE-}/g ; s/<__instance>/${__instance-}/g ; s/<__Instance>/${__Instance-}/g" \
            "${TemplateFile}" > "${InstanceFile}"
    fi
    echo "${InstanceFile}"
}

test_instance_file() {
    for AppName in watchtower watchtower__number2; do
    for Suffix in ".labels.yml" ".global.env"; do
            notice "[${AppName}] [${Suffix}]"
            local InstanceFile
            InstanceFile="$(run_script 'instance_file' "${AppName}" "${Suffix}")"
            notice "[${InstanceFile}]"
            cat "${InstanceFile}"
        done
    done
}
