#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_description() {
    # Return the description of the appname passed.
    local appname=${1-}
    appname=${appname,,}
    local LABELS_FILE="${TEMPLATES_FOLDER}/${appname}/${appname}.labels.yml"
    if [[ -f ${LABELS_FILE} ]]; then
        grep --color=never -Po "\scom\.dockstarter\.appinfo\.description: \K.*" "${LABELS_FILE}" | sed -E 's/^([^"].*[^"])$/"\1"/' | xargs || echo "! Missing description !"
    else
        echo "! Missing application !"
    fi

}

test_app_description() {
    notice "[WATCHTOWER]"
    run_script 'app_description' WATCHTOWER
    notice "[RADARR__4K]"
    run_script 'app_description' RADARR__4K
}
