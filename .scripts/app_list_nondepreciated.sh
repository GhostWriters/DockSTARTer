#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_list_nondepreciated() {
    for APPNAME in $(run_script 'app_list_builtin'); do
        if run_script 'app_is_nondepreciated' "${APPNAME}"; then
            echo "${APPNAME}"
        fi
    done
}

test_app_list_nondepreciated() {
    run_script 'app_list_nondepreciated'
    # warn "CI does not test app_list_nondepreciated."
}
