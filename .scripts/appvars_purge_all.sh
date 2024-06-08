#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

appvars_purge_all() {
    if grep -q -P '_ENABLED='"'"'?false'"'"'?$' "${COMPOSE_ENV}"; then
        if [[ ${CI-} == true ]] || run_script 'question_prompt' "${PROMPT:-CLI}" Y "Would you like to purge variables for all disabled apps?"; then
            info "Purging disabled app variables."
            while IFS= read -r line; do
                local APPNAME=${line%%_ENABLED=*}
                run_script 'appvars_purge' "${APPNAME}"
            done < <(grep --color=never -P '_ENABLED='"'"'?false'"'"'?$' "${COMPOSE_ENV}")
        fi
    else
        notice "${COMPOSE_ENV} does not contain any disabled apps."
    fi
}

test_appvars_purge_all() {
    run_script 'appvars_purge_all'
    run_script 'env_update'
    cat "${COMPOSE_ENV}"
}
