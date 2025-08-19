#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_nicename_from_template() {
    # Return the "NiceName" of the appname(s) passed. If there is no "NiceName", return the "Title__Case" of "appname"
    local AppList
    AppList="$(xargs -n 1 <<< "$*")"
    for APPNAME in ${AppList}; do
        local AppName="${APPNAME%:*}"
        local -l appname=${AppName}
        local LABELS_FILE
        LABELS_FILE="$(run_script 'app_instance_file' "${appname}" "*.labels.yml")"
        if [[ -f ${LABELS_FILE} ]]; then
            grep --color=never -Po "\scom\.dockstarter\.appinfo\.nicename: \K.*" "${LABELS_FILE}" | sed -E 's/^([^"].*[^"])$/"\1"/' | xargs || echo "${appname}"
        else
            sed -E "s/[[:alnum:]]+/\u&/g" <<< "${appname}"
        fi
    done

}

test_app_nicename_from_template() {
    for AppName in WATCHTOWER SAMBA RADARR NZBGET NONEXISTENTAPP; do
        local Result="no"
        Result="$(run_script 'app_nicename_from_template' "${AppName}")"
        notice "[${AppName}] [${Result}]"
    done
}
