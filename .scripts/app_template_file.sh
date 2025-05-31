#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_template_file() {
    # app_template_file AppName FileSuffix
    # Returns the filename of a file in the template folder for the app specified
    #
    # app_template_file "radarr" ".labels.yml" will return a string similar to "/home/user/.docker/compose/.apps/radarr/radarr.labels.yml"

    local AppName=${1:-}
    local FileSuffix=${2:-}
    local appname=${AppName,,}

    echo "${TEMPLATES_FOLDER}/${appname}/${appname}${FileSuffix}"
}

test_app_template_file() {
    for AppName in watchtower radarr; do
        for Suffix in ".labels.yml" ".global.env"; do
            notice "[${AppName}] [${Suffix}]"
            local TemplateFile
            TemplateFile="$(run_script 'app_template_file' "${AppName}" "${Suffix}")"
            notice "[${TemplateFile}]"
            cat "${TemplateFile}"
        done
    done
}
