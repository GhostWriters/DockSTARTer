#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

env_create() {
    if [[ -f ${SCRIPTPATH}/compose/.env ]]; then
        info "${SCRIPTPATH}/compose/.env found."
    else
        warning "${SCRIPTPATH}/compose/.env not found. Copying example template."
        cp "${SCRIPTPATH}/compose/.env.example" "${SCRIPTPATH}/compose/.env"
        info "Example template has been copied. You should exit the script and edit ${SCRIPTPATH}/compose/.env before continuing."
        info "Exit now?"
        local YN
        while true; do
            if [[ ${CI:-} == true ]] && [[ ${TRAVIS:-} == true ]]; then
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
        echo
    fi
}
