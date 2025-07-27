#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_list() {
    local -a AppList
    readarray -t AppList < <(run_script 'app_nicename' "$(run_script 'app_list_builtin')")
    for index in "${!AppList[@]}"; do
        local AppName=${AppList[index]}
        AppList[index]+=','
        if run_script 'app_is_deprecated' "${AppName}"; then
            AppList[index]+='[*DEPRECATED*]'
        fi
        AppList[index]+=','
        if run_script 'app_is_added' "${AppName}"; then
            AppList[index]+='*ADDED*'
            if run_script 'app_is_disabled' "${AppName}"; then
                AppList[index]+=',(Disabled)'
            fi
        fi
    done
    printf '%s\n' "${AppList[@]}" | column -t -s ','
}

test_app_list() {
    run_script 'env_create'
    run_script 'app_list'
    # warn "CI does not test app_list."
}
