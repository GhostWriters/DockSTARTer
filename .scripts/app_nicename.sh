#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_nicename() {
    # Return the "NiceName" of the appname passed. If there is no "NiceName", return the lower case "appname"
    local appname=${1-}
    appname=${appname,,}

    grep --color=never -s -Po "\scom\.dockstarter\.appinfo\.nicename: \K.*" "${TEMPLATES_FOLDER}/${appname}/${appname}.labels.yml" | sed -E 's/^([^"].*[^"])$/"\1"/' | xargs || echo "${appname}"

}

test_app_nicename() {
    notice "[WATCHTOWER]"
    run_script 'app_nicename' WATCHTOWER
    notice "[RADARR__4K]"
    run_script 'app_nicename' RADARR__4K
}
