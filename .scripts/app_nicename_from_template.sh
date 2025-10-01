#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_nicename_from_template() {
    # Return the "NiceName" of the appname(s) passed. If there is no "NiceName", return the "Title__Case" of "appname"
    local AppList
    AppList="$(xargs -n 1 <<< "$*")"
    for APPNAME in ${AppList}; do
        local AppName="${APPNAME%:*}"
        local -l baseapp instance
        local BaseApp Instance
        baseapp=$(run_script 'appname_to_baseappname' "${AppName}")
        BaseApp="${baseapp^}"
        labels_yml="$(run_script 'app_instance_file' "${baseapp}" "*.labels.yml")"
        if [[ -f ${labels_yml} ]]; then
            BaseApp="$(
                grep --color=never -Po "\scom\.dockstarter\.appinfo\.nicename: \K.*" "${labels_yml}" | sed -E 's/^([^"].*[^"])$/"\1"/' | xargs
            )"
        fi
        instance=$(run_script 'appname_to_instancename' "${AppName}")
        Instance=""
        if [[ -n ${instance} ]]; then
            Instance="__${instance^}"
        fi
        echo "${BaseApp}${Instance}"
    done
}

test_app_nicename_from_template() {
    for AppName in WATCHTOWER SAMBA RADARR NZBGET NZBGET__INSTANCE NONEXISTENTAPP; do
        local Result="no"
        Result="$(run_script 'app_nicename_from_template' "${AppName}")"
        notice "[${AppName}] [${Result}]"
    done
}
