#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_filter_runnable() {
    local AppList
    AppList="$(xargs -n 1 <<< "$*")"
    for AppName in ${AppList}; do
        if run_script 'app_is_runnable' "${AppName}"; then
            echo "${AppName}"
        fi
    done
}

test_app_filter_runnable() {
    warn "CI does not test app_filter_runnable."
}
