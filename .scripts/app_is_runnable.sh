#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_is_runnable() {
    local -l appname=${1-}
    local -l basename
    basename=$(run_script 'appname_to_baseappname' "${appname}")
    local main_yml
    main_yml="$(run_script 'app_template_file' "${basename}" "*.yml")"
    local arch_yml
    arch_yml="$(run_script 'app_template_file' "${basename}" "*.${ARCH}.yml")"
    [[ -f ${main_yml} && -f ${arch_yml} ]]
}

test_app_is_runnable() {
    run_script 'app_is_disabled' WATCHTOWER
    notice "'app_is_disabled' WATCHTOWER returned $?"
    run_script 'app_is_disabled' APPTHATDOESNOTEXIST
    notice "'app_is_disabled' APPTHATDOESNOTEXIST returned $?"
    #warn "CI does not test app_is_disabled."
}
