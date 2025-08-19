#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_instance_folder() {
    # app_instance_folder AppName
    # Returns the folder name of a folder in the instance folder for the app specified
    #
    # app_instance_folder "radarr"" will return a string similar to "/home/user/.docker/compose/.instances/radarr"
    # If the folder does not exist, it is created from the matching folder in the "templates" folder.

    local AppName=${1:-}
    local -l appname=${AppName}

    local baseapp TemplateFolder InstanceFolder
    baseapp="$(run_script 'appname_to_baseappname' "${appname}")"
    TemplateFolder="${TEMPLATES_FOLDER}/${baseapp}"
    InstanceFolder="${INSTANCES_FOLDER}/${appname}"

    echo "${InstanceFolder}"
    if [[ ! -d ${InstanceFolder} ]]; then
        if [[ ! -d ${TemplateFolder} ]]; then
            warn "Folder '${C["Folder"]}${TemplateFolder}${NC}' does not exist."
            return
        fi
        if [[ ! -d ${InstanceFolder} ]]; then
            mkdir -p "${InstanceFolder}" ||
                fatal "Failed to create folder '${C["Folder"]}${InstanceFolder}${NC}'. Failing command: ${C["FailingCommand"]}mkdir -p \"${InstanceFolder}\""
            run_script 'set_permissions' "${InstanceFolder}"
        fi
    fi

}

test_app_instance_folder() {
    for AppName in watchtower watchtower__number2; do
        notice "[${AppName}]"
        local InstanceFolder
        InstanceFolder="$(run_script 'app_instance_folder' "${AppName}")"
        notice "[${InstanceFolder}]"
        ls -lah "${InstanceFolder}"
    done
}
