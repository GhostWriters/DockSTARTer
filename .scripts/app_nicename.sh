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
    local ForcePass=''
    local -i result=0
    run_script 'appvars_create' WATCHTOWER NZBGET
    local -a Test=(
        WATCHTOWER Watchtower
        SAMBA Samba
        RADARR Radarr
        nzbget NZBGet
        NZBGet NZBGet
        NZBGET NZBGet
        NONEXISTENTAPP Nonexistentapp
        WATCHTOWER__INSTANCE Watchtower__Instance
        SAMBA__INSTANCE Samba__Instance
        RADARR__INSTANCE Radarr__Instance
        NZBGET__INSTANCE Nzbget__Instance
        NONEXISTENTAPP__INSTANCE Nonexistentapp__Instance
    )
    run_unit_tests_pipe "App" "App" "${ForcePass}" < <(
        for ((i = 0; i < ${#Test[@]}; i += 2)); do
            printf '%s\n' \
                "${Test[i]}" \
                "${Test[i + 1]}" \
                "$(run_script 'app_nicename' "${Test[i]}")"
        done
    )
    result=$?
    run_script 'appvars_purge' WATCHTOWER NZBGET
    return ${result}
}
