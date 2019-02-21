#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

config_global() {
    local PROMPT
    PROMPT=${1:-false}
    local APPNAME
    APPNAME="Global"
    local VARNAMES
    VARNAMES=(TZ DOCKERHOSTNAME PUID PGID DOCKERCONFDIR DOWNLOADSDIR MEDIADIR_BOOKS MEDIADIR_COMICS MEDIADIR_MOVIES MEDIADIR_MUSIC MEDIADIR_TV DOCKERSHAREDDIR)
    local APPVARS
    APPVARS=$(for v in "${VARNAMES[@]}"; do echo "${v}=$(run_script 'env_get' "${v}")"; done)

    if run_script 'question_prompt' "${PROMPT}" N "Would you like to keep these settings for ${APPNAME}?\\n\\n${APPVARS}"; then
        info "Keeping ${APPNAME} .env variables."
    else
        info "Configuring ${APPNAME} .env variables."
        while IFS= read -r line; do
            SET_VAR=${line%%=*}
            run_script 'menu_value_prompt' "${SET_VAR}" || return 1
        done < <(echo "${APPVARS}")
    fi
}
