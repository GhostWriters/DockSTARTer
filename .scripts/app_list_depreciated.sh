#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_list_depreciated() {
    for APPNAME in $(run_script 'app_list_builtin'); do
        if run_script 'app_is_depreciated' "${APPNAME}"; then
            echo "${APPNAME}"
        fi
    done
}

test_app_list_depreciated() {
    run_script 'app_list_depreciated'
    # warn "CI does not test app_list_depreciated."
}
