#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_is_deprecated() {
    local -l appname=${1-}
    local -l baseappname
    baseappname=$(run_script 'appname_to_baseappname' "${appname}")
    local labels_yml
    labels_yml="$(run_script 'app_template_file' "${baseappname}" "*.labels.yml")"
    local APP_DEPRECATED
    if [[ -f ${labels_yml} ]]; then
        APP_DEPRECATED="$(grep --color=never -Po "\scom\.dockstarter\.appinfo\.deprecated: \K.*" "${labels_yml}" | sed -E 's/^([^"].*[^"])$/"\1"/' | xargs || echo false)"
    fi
    if [[ ${APP_DEPRECATED-} == "true" ]]; then
        return 0
    else
        return 1
    fi
}

test_app_is_deprecated() {
    run_script 'app_is_deprecated' WATCHTOWER
    notice "'app_is_deprecated' WATCHTOWER returned $?"
    run_script 'app_is_deprecated' SAMBA
    notice "'app_is_deprecated' SAMBA returned $?"
    run_script 'app_is_deprecated' APPTHATDOESNOTEXIST
    notice "'app_is_deprecated' APPTHATDOESNOTEXIST returned $?"
    #warn "CI does not test app_is_deprecated."
}
