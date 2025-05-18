#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

instance_folder() {
    # instance_folder AppName
    # Returns the folder name of a folder in the instance folder for the app specified
    #
    # instance_folder "radarr"" will return a string similar to "/home/user/.docker/compose/.instances/radarr"
    # If the folder does not exist, it is created from the matching folder in the "templates" folder.

    local AppName=${1:-}
    local appname=${AppName,,}

    local baseapp instance TemplateFolder InstanceFolder
    baseapp="$(run_script 'appname_to_baseappname' "${appname}")"
    instance="$(run_script 'appname_to_instancename' "${appname}")"
    TemplateFolder="${TEMPLATES_FOLDER}/${baseapp}"
    InstanceFolder="${INSTANCES_FOLDER}/${appname}"

    if [[ ! -d ${InstanceFolder} ]]; then
        if [[ ! -f ${TemplateFolder} ]]; then
            warn "${TemplateFolder} does not exist."
            return
        fi
        if [[ ! -d ${InstanceFolder} ]]; then
            mkdir -p "${InstanceFolder}" ||
                fatal "Failed to create folder ${InstanceFolder}. ${F[C]}Failing command: mkdir -p \"${InstanceFolder}\""
        fi
    fi

    echo "${InstanceFolder}"
}

test_instance_folder() {
    for AppName in watchtower watchtower__number2; do
        notice "[${AppName}]"
        local InstanceFolder
        InstanceFile="$(run_script 'instance_folder' "${AppName}")"
        notice "[${InstanceFolder}]"
        ls "${InstanceFolder}"
    done
}
