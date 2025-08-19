#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_instance_file() {
    # app_instance_file AppName FilenameTemplate
    # Returns the filename of a file in the instance folder for the app specified
    #
    # app_instance_file "radarr" "*.labels.yml" will return a string similar to "/home/user/.docker/compose/.instances/radarr/radarr.labels.yml"
    # If the file does not exist, it is created from the matching file in the "templates" folder.

    local -l appname=${1:-}
    local FilenameTemplate=${2:-}

    if [[ ! -d ${INSTANCES_FOLDER} ]]; then
        mkdir -p "${INSTANCES_FOLDER}" ||
            fatal "Failed to create folder '${C["Folder"]}${INSTANCES_FOLDER}${NC}'. Failing command: mkdir -p \"${INSTANCES_FOLDER}\""
        run_script 'set_permissions' "${INSTANCES_FOLDER}"
    fi

    local -l baseapp
    baseapp="$(run_script 'appname_to_baseappname' "${appname}")"

    local TemplateFolder="${TEMPLATES_FOLDER}/${baseapp}"
    local InstanceTemplateFolder="${INSTANCES_FOLDER}/${TEMPLATES_FOLDER_NAME}/${appname}"
    local InstanceFolder="${INSTANCES_FOLDER}/${appname}"

    local TemplateFile="${TemplateFolder}/${FilenameTemplate//"*"/"${baseapp}"}"
    local InstanceTemplateFile="${InstanceTemplateFolder}/${FilenameTemplate//"*"/"${appname}"}"
    local InstanceFile="${InstanceFolder}/${FilenameTemplate//"*"/"${appname}"}"

    echo "${InstanceFile}"

    if [[ ! -d ${TemplateFolder} ]]; then
        # Template folder doesn't exist, remove any instance folders associated with it and return
        for Folder in "${InstanceTemplateFolder}" "${InstanceFolder}"; do
            if [[ -d ${Folder} ]]; then
                run_script 'set_permissions' "${Folder}"
                rm -rf "${Folder}" &> /dev/null ||
                    error "Failed to remove directory.\nFailing command: ${C["FailingCommand"]}rm -rf \"${Folder}\""
            fi
        done
        return
    fi

    if [[ ! -f ${TemplateFile} ]]; then
        # Template file doesn't exist, remove any instance files associated with it and return
        for File in "${InstanceTemplateFile}" "${InstanceFile}"; do
            if [[ -f ${File} ]]; then
                run_script 'set_permissions' "${File}"
                rm -f "${File}" &> /dev/null ||
                    error "Failed to remove file.\nFailing command: ${C["FailingCommand"]}rm -f \"${File}\""
            fi
        done
        return
    fi

    if [[ -f ${InstanceFile} && -f ${InstanceTemplateFile} ]] && cmp -s "${TemplateFile}" "${InstanceTemplateFile}"; then
        # The instance file exists, and the template file has not changed, nothing to do.
        return
    fi

    # If we got here, the instance file needs to be created

    if [[ ! -d ${InstanceFolder} ]]; then
        # Create the folder to place the instance file in
        mkdir -p "${InstanceFolder}" ||
            fatal "Failed to create folder '${C["Folder"]}${InstanceFolder}${NC}'. Failing command: ${C["FailingCommand"]}mkdir -p \"${InstanceFolder}\""
        run_script 'set_permissions' "${InstanceFolder}"
    fi

    # Create the instance file based on the template file
    local instance
    instance="$(run_script 'appname_to_instancename' "${appname}")"
    local __INSTANCE __Instance __instance
    if [[ -n ${instance} ]]; then
        __INSTANCE="__${instance^^}"
        __Instance="__${instance^}"
        __instance="__${instance,,}"
    fi
    sed -e "s/<__INSTANCE>/${__INSTANCE-}/g ; s/<__instance>/${__instance-}/g ; s/<__Instance>/${__Instance-}/g" \
        "${TemplateFile}" > "${InstanceFile}"
    run_script 'set_permissions' "${InstanceFile}"

    if [[ ! -d ${InstanceTemplateFolder} ]]; then
        # Create the folder to place the copy of the template file in
        mkdir -p "${InstanceTemplateFolder}" ||
            fatal "Failed to create folder '${C["Folder"]}${InstanceTemplateFolder}${NC}'. Failing command: ${C["FailingCommand"]}mkdir -p \"${InstanceTemplateFolder}\""
        run_script 'set_permissions' "${InstanceTemplateFolder}"
    fi

    # Copy the original template file
    cp "${TemplateFile}" "${InstanceTemplateFile}" ||
        fatal "Failed to copy file.\nFailing command: ${C["FailingCommand"]}cp \"${TemplateFile}\" \"${InstanceTemplateFile}\""
    run_script 'set_permissions' "${InstanceTemplateFile}"
}

test_app_instance_file() {
    for AppName in watchtower watchtower__number2; do
        for Template in "*.labels.yml" ".env"; do
            notice "[${AppName}] [${Template}]"
            local InstanceFile
            InstanceFile="$(run_script 'app_instance_file' "${AppName}" "${Template}")"
            notice "[${InstanceFile}]"
            cat "${InstanceFile}"
        done
    done
}
