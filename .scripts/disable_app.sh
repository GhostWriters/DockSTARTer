#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

disable_app() {
    # Disable the list of apps given.  Apps will be seperate arguments and/or seperated by spaces
    local AppList
    AppList=$(xargs -n 1 <<< "$*")
    for AppName in ${AppList}; do
        if run_script 'app_is_builtin' "${AppName}"; then
            info "Disabling application${AppName^^}"
            run_script 'env_set' "${AppName^^}__ENABLED" false
        else
            warn "Application ${AppName^^} does not exist."
        fi
    done
}

test_disable_app() {
    #run_script 'disable_app' watchtower "samba radarr"
    #cat "${COMPOSE_ENV}"
    warn "CI does not test disable_app."
}
