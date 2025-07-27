#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_list_nondeprecated() {
    for APPNAME in $(run_script 'app_list_builtin'); do
        if run_script 'app_is_nondeprecated' "${APPNAME}"; then
            echo "${APPNAME}"
        fi
    done
}

test_app_list_nondeprecated() {
    run_script 'app_list_nondeprecated'
    # warn "CI does not test app_list_nondeprecated."
}
