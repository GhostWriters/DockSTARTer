#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_description_from_template() {
    # Return the description of the appname passed.
    local appname=${1-}
    appname=${appname,,}
    if run_script 'app_is_builtin' "${appname}"; then
        local LABELS_FILE
        LABELS_FILE="$(run_script 'app_instance_file' "${appname}" ".labels.yml")"
        if [[ -f ${LABELS_FILE} ]]; then
            grep --color=never -Po "\scom\.dockstarter\.appinfo\.description: \K.*" "${LABELS_FILE}" | sed -E 's/^([^"].*[^"])$/"\1"/' | xargs || echo "! Missing description !"
        else
            echo "! Missing application !"
        fi
    else
        local AppName
        AppName="$(run_script 'app_nicename' "${appname}")"
        echo "${AppName} is a user defined application"
    fi
}

test_app_description_from_template() {
    notice "[WATCHTOWER]"
    run_script 'app_description_from_template' WATCHTOWER
    notice "[RADARR__4K]"
    run_script 'app_description_from_template' RADARR__4K
}
