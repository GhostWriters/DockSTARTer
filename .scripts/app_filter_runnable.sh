#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_filter_runnable() {
    local AppList
    AppList="$(xargs -n 1 <<< "$*")"
    for AppName in ${AppList}; do
        local -l basename
        basename=$(run_script 'appname_to_baseappname' "${AppName}")
        local main_yml="${TEMPLATES_FOLDER}/${basename}/${basename}.yml"
        local arch_yml="${TEMPLATES_FOLDER}/${basename}/${basename}.${ARCH}.yml"
        if [[ -f ${main_yml} && -f ${arch_yml} ]]; then
            echo "${AppName}"
        fi
    done
}

test_app_filter_runnable() {
    warn "CI does not test app_filter_runnable."
}
