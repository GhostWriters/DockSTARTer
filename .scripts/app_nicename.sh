#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_nicename() {
    # Return the "NiceName" of the appname(s) passed. If there is no "NiceName", return the "Title__Case" of "appname"
    local AppList
    AppList="$(xargs -n 1 <<< "$*")"
    for APPNAME in ${AppList}; do
        local AppName="${APPNAME%:*}"
        if ! run_script 'app_is_user_defined' "${AppName}"; then
            run_script 'app_nicename_from_template' "${AppName}"
            continue
        fi

        local -l baseapp instance
        local BaseApp Instance
        baseapp=$(run_script 'appname_to_baseappname' "${AppName}")
        BaseApp="${baseapp^}"
        instance=$(run_script 'appname_to_instancename' "${AppName}")
        Instance=""
        if [[ -n ${instance} ]]; then
            Instance="__${instance^}"
        fi
        echo "${BaseApp}${Instance}"
    done

}

test_app_nicename() {
    for AppName in WATCHTOWER SAMBA RADARR NZBGET NONEXISTENTAPP; do
        local Result="no"
        Result="$(run_script 'app_nicename' "${AppName}")"
        notice "[${AppName}] [${Result}]"
    done
}
