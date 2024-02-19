#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

config_global() {
    local APPNAME="Global"
    local VARNAMES=(DOCKER_VOLUME_CONFIG DOCKER_VOLUME_STORAGE DOCKER_HOSTNAME PGID PUID TZ)
    local APPVARS
    APPVARS=$(for v in "${VARNAMES[@]}"; do echo "${v}=$(run_script 'env_get' "${v}")"; done)

    if run_script 'question_prompt' "${PROMPT-}" N "Would you like to keep these settings for ${APPNAME}?\\n\\n${APPVARS}"; then
        info "Keeping ${APPNAME} .env variables."
    else
        info "Configuring ${APPNAME} .env variables."
        while IFS= read -r line; do
            local SET_VAR=${line%%=*}
            run_script 'menu_value_prompt' "${SET_VAR}" || return 1
        done < <(echo "${APPVARS}")
    fi
}

test_config_global() {
    # run_script 'config_global'
    warn "CI does not test config_global."
}
