#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

appvars_purge_all() {
    local PREPROMPT=${PROMPT:-}
    if [[ ${CI:-} != true ]] && [[ ${PROMPT:-} != "GUI" ]]; then
        PROMPT="CLI"
    fi
    if grep -q '_ENABLED=false$' "${SCRIPTPATH}/compose/.env"; then
        if [[ ${CI:-} == true ]] || run_script 'question_prompt' N "Would you like to purge variables for all disabled apps?"; then
            info "Purging disabled app variables."
            while IFS= read -r line; do
                local APPNAME=${line%%_ENABLED=false}
                run_script 'appvars_purge' "${APPNAME}"
            done < <(grep '_ENABLED=false$' < "${SCRIPTPATH}/compose/.env")
        fi
    fi
    PROMPT=${PREPROMPT:-}

}

test_appvars_purge_all() {
    run_script 'appvars_purge_all'
    cat "${SCRIPTPATH}/compose/.env"
}
