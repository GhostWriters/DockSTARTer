#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_description() {
    # Return the description of the appname passed.
    local -l appname=${1-}
    appname="${appname%:*}"
    if run_script 'app_is_user_defined' "${appname}"; then
        local AppName
        AppName="$(run_script 'app_nicename' "${appname}")"
        echo "${AppName} is a user defined application"
    else
        local LABELS_FILE
        LABELS_FILE="$(run_script 'app_instance_file' "${appname}" "*.labels.yml")"
        if [[ -f ${LABELS_FILE} ]]; then
            grep --color=never -Po "\scom\.dockstarter\.appinfo\.description: \K.*" "${LABELS_FILE}" | sed -E 's/^([^"].*[^"])$/"\1"/' | xargs || echo "! Missing description !"
        else
            echo "! Missing application !"
        fi
    fi
}

test_app_description() {
    for AppName in WATCHTOWER SAMBA RADARR NZBGET NONEXISTENTAPP; do
        local Result="no"
        Result="$(run_script 'app_description' "${AppName}")"
        notice "[${AppName}] [${Result}]"
    done
}
