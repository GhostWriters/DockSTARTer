#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

env_create() {
    local PROMPT
    PROMPT=${1:-}
    if [[ -f ${SCRIPTPATH}/compose/.env ]]; then
        info "${SCRIPTPATH}/compose/.env found."
    else
        warning "${SCRIPTPATH}/compose/.env not found. Copying example template."
        cp "${SCRIPTPATH}/compose/.env.example" "${SCRIPTPATH}/compose/.env" || fatal "${SCRIPTPATH}/compose/.env could not be copied."
        [[ ${PROMPT} != "menu" ]] && info "You should exit the script and edit ${SCRIPTPATH}/compose/.env before continuing. Exit now?"
        local YN
        while true; do
            if [[ ${CI:-} == true ]] && [[ ${TRAVIS:-} == true ]]; then
                YN=N
            elif [[ ${PROMPT} == "menu" ]]; then
                YN=N
            else
                read -rp "[Yn]" YN
            fi
            case ${YN} in
                [Yy]* )
                    info "Please edit ${SCRIPTPATH}/compose/.env and rerun the script."
                    exit 0
                    ;;
                [Nn]* )
                    warning "Defaults from ${SCRIPTPATH}/compose/.env.example will be used."
                    break
                    ;;
                * )
                    error "Please answer yes or no."
                    ;;
            esac
        done
    fi
}
