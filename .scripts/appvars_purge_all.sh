#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

appvars_purge_all() {
    local Title="Purge All Variables"
    local DISABLED_APPS
    DISABLED_APPS="$(run_script 'app_list_disabled')"
    if [[ -n ${DISABLED_APPS-} ]]; then
        if [[ ${CI-} == true ]] || run_script 'question_prompt' Y "Would you like to purge variables for all disabled apps?" "${Title}" "${FORCE:+Y}"; then
            info "Purging disabled app variables."
            for APPNAME in ${DISABLED_APPS-}; do
                run_script 'appvars_purge' "${APPNAME}"
            done
        fi
    else
        notice "'${C["File"]}${COMPOSE_ENV}${NC}' does not contain any disabled apps."
    fi
}

test_appvars_purge_all() {
    run_script 'appvars_purge_all'
    run_script 'env_update'
    cat "${COMPOSE_ENV}"
}
