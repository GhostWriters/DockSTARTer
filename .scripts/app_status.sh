#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_status() {
    # Enable the status of apps given.  Apps will be seperate arguments and/or seperated by spaces
    local AppList
    AppList=$(xargs -n 1 <<< "$*")
    for AppName in ${AppList}; do
        if ! run_script 'app_is_builtin' "${AppName}"; then
            echo "Application ${AppName^^} does not exist."
            continue
        fi
        if ! run_script 'app_is_installed' "${AppName}"; then
            echo "Application ${AppName^^} is not installed."
            continue
        fi
        if run_script 'app_is_enabled' "${AppName}"; then
            echo "Application ${AppName^^} is enabled."
        else
            echo "Application ${AppName^^} is disabled."
        fi
    done
}

test_app_status() {
    #run_script 'app_status' watchtower "samba radarr"
    #cat "${COMPOSE_ENV}"
    warn "CI does not test app_status."
}
