#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_is_runnable() {
    local appname=${1-}
    local basename
    basename=$(run_script 'appname_to_baseappname' "${appname}")
    basename=${basename,,}
    local main_yml="${TEMPLATES_FOLDER}/${basename}/${basename}.yml"
    local arch_yml="${TEMPLATES_FOLDER}/${basename}/${basename}.${ARCH}.yml"
    [[ -f ${main_yml} && -f ${arch_yml} ]]
}

test_app_is_runnable() {
    run_script 'app_is_disabled' WATCHTOWER
    notice "'app_is_disabled' WATCHTOWER returned $?"
    run_script 'app_is_disabled' APPTHATDOESNOTEXIST
    notice "'app_is_disabled' APPTHATDOESNOTEXIST returned $?"
    #warn "CI does not test app_is_disabled."
}
