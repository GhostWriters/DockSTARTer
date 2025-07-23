#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_instance_file() {
    # app_instance_file AppName FileSuffix
    # Returns the filename of a file in the instance folder for the app specified
    #
    # app_instance_file "radarr" ".labels.yml" will return a string similar to "/home/user/.docker/compose/.instances/radarr/radarr.labels.yml"
    # If the file does not exist, it is created from the matching file in the "templates" folder.

    local AppName=${1:-}
    local FileSuffix=${2:-}
    local appname=${AppName,,}

    if [[ ! -d ${INSTANCES_FOLDER} ]]; then
        mkdir -p "${INSTANCES_FOLDER}" ||
            fatal "Failed to create folder ${F[C]}${INSTANCES_FOLDER}${NC}. ${F[C]}Failing command: mkdir -p \"${INSTANCES_FOLDER}\""
        run_script 'set_permissions' "${INSTANCES_FOLDER}"
    fi

    local InstanceFolder
    InstanceFolder="${INSTANCES_FOLDER}/${appname}"
    if [[ ! -d ${InstanceFolder} ]]; then
        mkdir -p "${InstanceFolder}" ||
            fatal "Failed to create folder ${F[C]}${InstanceFolder}${NC}. ${F[C]}Failing command: mkdir -p \"${InstanceFolder}\""
        run_script 'set_permissions' "${InstanceFolder}"
    fi

    local InstanceFile
    InstanceFile="${InstanceFolder}/${appname}${FileSuffix}"
    echo "${InstanceFile}"
    if [[ -f ${InstanceFile} ]]; then
        # File already exists, nothing to do
        return
    fi

    local baseapp
    baseapp="$(run_script 'appname_to_baseappname' "${appname}")"
    local TemplateFile
    TemplateFile="$(run_script 'app_template_file' "${baseapp}" "${FileSuffix}")"
    if [[ ! -f ${TemplateFile} ]]; then
        # Template file doesn't exist, nothing to do.
        return
    fi

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
}

test_app_instance_file() {
    for AppName in watchtower watchtower__number2; do
        for Suffix in ".labels.yml" ".global.env"; do
            notice "[${AppName}] [${Suffix}]"
            local InstanceFile
            InstanceFile="$(run_script 'app_instance_file' "${AppName}" "${Suffix}")"
            notice "[${InstanceFile}]"
            cat "${InstanceFile}"
        done
    done
}
