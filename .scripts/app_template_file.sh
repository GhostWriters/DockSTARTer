#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_template_file() {
    # app_template_file AppName FilenameTemplate
    # Returns the filename of a file in the template folder for the app specified
    #
    # app_template_file "radarr" "*.labels.yml" will return a string similar to "/home/user/.docker/compose/.apps/radarr/radarr.labels.yml"

    local -l appname=${1:-}
    local FilenameTemplate=${2:-}

    echo "${TEMPLATES_FOLDER}/${appname}/${FilenameTemplate//"*"/"${appname}"}"
}

test_app_template_file() {
    for appname in watchtower radarr; do
        for Template in "*.labels.yml" ".env"; do
            notice "[${appname}] [${Template}]"
            local TemplateFile
            TemplateFile="$(run_script 'app_template_file' "${appname}" "${Template}")"
            notice "[${TemplateFile}]"
            cat "${TemplateFile}"
        done
    done
}
