#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_app_vars() {
    local Title="Application Vars"
    local APPNAME=${1-}
    run_script 'appvars_create' "${APPNAME}"
    local APPVARS
    APPVARS=$(run_script 'appvars_lines' "${APPNAME}")
    if [[ -z ${APPVARS} ]]; then
        if [[ ${CI-} == true ]]; then
            warn "${APPNAME} has no variables."
        else
            local AppVarsDialog=(
                --clear
                --title "${Title}"
                --msgbox "${APPNAME} has no variables."
                0 0
            )
            dialog "${AppVarsDialog[@]}"
            clear
        fi
        return
    fi

    if run_script 'question_prompt' "${PROMPT-}" Y "Would you like to keep these settings for ${APPNAME}?\\n\\n${APPVARS}" "${Title}"; then
        info "Keeping ${APPNAME} .env variables."
    else
        info "Configuring ${APPNAME} .env variables."
        while IFS= read -r line; do
            local SET_VAR=${line%%=*}
            run_script 'menu_value_prompt' "${SET_VAR}" || return 1
        done < <(echo "${APPVARS}")
    fi
}

test_menu_app_vars() {
    # run_script 'menu_app_vars'
    warn "CI does not test menu_app_vars."
}
