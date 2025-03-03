#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

enable_app() {
    # Enable the list of apps given.  Apps will be seperate arguments and/or seperated by spaces
    local AppList
    AppList=$(xargs -n 1 <<< "$*")
    for AppName in ${AppList}; do
        notice "Enabling ${AppName^^}"
        run_script 'env_set' "${AppName^^}__ENABLED" true
    done
}

test_enable_app() {
    #run_script 'enable_app' watchtower "samba radarr"
    #cat "${COMPOSE_ENV}"
    warn "CI does not test enable_app."
}
