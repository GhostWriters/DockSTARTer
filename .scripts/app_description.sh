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
        run_script 'app_description_from_template' "${appname}"
    fi
}

test_app_description() {
    local ForcePass='' # Force the tests to pass even on failure if set to a non-empty value
    local -i result=0
    run_script 'appvars_create' WATCHTOWER NZBGET
    local -a Test=(
        WATCHTOWER "Automatically update running Docker containers"
        SAMBA "Samba is a user defined application"
        RADARR "Radarr is a user defined application"
        nzbget "Efficient usenet downloader"
        NZBGet "Efficient usenet downloader"
        NZBGET "Efficient usenet downloader"
        NONEXISTENTAPP "Nonexistentapp is a user defined application"
        WATCHTOWER__INSTANCE "Watchtower__Instance is a user defined application"
        SAMBA__INSTANCE "Samba__Instance is a user defined application"
        RADARR__INSTANCE "Radarr__Instance is a user defined application"
        NZBGET__INSTANCE "Nzbget__Instance is a user defined application"
        NONEXISTENTAPP__INSTANCE "Nonexistentapp__Instance is a user defined application"
    )
    run_unit_tests_pipe "App" "App" "${ForcePass}" < <(
        for ((i = 0; i < ${#Test[@]}; i += 2)); do
            printf '%s\n' \
                "${Test[i]}" \
                "${Test[i + 1]}" \
                "$(run_script 'app_description' "${Test[i]}")"
        done
    )
    result=$?
    run_script 'appvars_purge' WATCHTOWER NZBGET
    return ${result}
}
