#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_nicename() {
    # Return the "NiceName" of the appname(s) passed. If there is no "NiceName", return the "Title__Case" of "appname"
    local AppList
    AppList=$(xargs -n 1 <<< "$*")
    for APPNAME in ${AppList}; do
        local AppName
        appname="${AppName,,}"
        appname="${AppName%:*}"
        if run_script 'app_is_user_defined' "${APPNAME}"; then
            echo "${AppName}"
            continue
        fi
        local LABELS_FILE
        LABELS_FILE="$(run_script 'app_instance_file' "${APPNAME}" ".labels.yml")"
        if [[ ! -f ${LABELS_FILE} ]]; then
            echo "${AppName}"
            continue
        fi
        # Return the 'nicename' from the label file
        grep --color=never -Po "\scom\.dockstarter\.appinfo\.nicename: \K.*" "${LABELS_FILE}" | sed -E 's/^([^"].*[^"])$/"\1"/' | xargs ||
            echo "${AppName}"
    done

}

test_app_nicename() {
    for AppName in WATCHTOWER SAMBA RADARR NZBGET NONEXISTENTAPP; do
        local Result="no"
        Result="$(run_script 'app_nicename' "${AppName}")"
        notice "[${AppName}] [${Result}]"
    done
}
