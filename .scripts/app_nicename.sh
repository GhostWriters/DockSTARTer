#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_nicename() {
    # Return the "NiceName" of the appname passed. If there is no "NiceName", return the lower case "appname"
    local appname=${1-}
    appname=${appname,,}
    local LABELS_FILE="${TEMPLATES_FOLDER}/${appname}/${appname}.labels.yml"
    if [[ -f ${LABELS_FILE} ]]; then
        grep --color=never -Po "\scom\.dockstarter\.appinfo\.nicename: \K.*" "${LABELS_FILE}" | sed -E 's/^([^"].*[^"])$/"\1"/' | xargs || echo "${appname}"
    else
        echo "${appname}"
    fi

}

test_app_nicename() {
    notice "[WATCHTOWER]"
    run_script 'app_nicename' WATCHTOWER
    notice "[RADARR__4K]"
    run_script 'app_nicename' RADARR__4K
}
