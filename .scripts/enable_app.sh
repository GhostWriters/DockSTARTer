#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

enable_app() {
    # Enable the list of apps given.  Apps will be seperate arguments and/or seperated by spaces
    local AppList
    AppList="$(xargs -n 1 <<< "$*")"
    for AppName in ${AppList}; do
        if run_script 'app_is_builtin' "${AppName}"; then
            EnabledVar="${AppName^^}__ENABLED"
            info "Enabling application ${F[C]}${AppName^^}${NC}"
            notice "Setting variable in ${F[C]}${COMPOSE_ENV}${NC}:"
            notice "   ${F[C]}${EnabledVar}='true'${NC}"
            run_script 'env_set' "${EnabledVar}" true
        else
            warn "Application ${F[C]}${AppName^^}${NC} does not exist."
        fi
    done
}

test_enable_app() {
    #run_script 'enable_app' watchtower "samba radarr"
    #cat "${COMPOSE_ENV}"
    warn "CI does not test enable_app."
}
