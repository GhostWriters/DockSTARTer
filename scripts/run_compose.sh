#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

run_compose() {
    if [[ ${CI:-} != true ]] && [[ ${TRAVIS:-} != true ]]; then
        echo
        info "Would you like to run your selected containers now?"
        local YN
        while true; do
            read -rp "[Yn]" YN
            case ${YN} in
                [Yy]* )
                    run_script 'install_docker'
                    run_script 'install_compose'
                    cd "${SCRIPTPATH}/compose/" || return 1
                    docker-compose up -d
                    cd "${SCRIPTPATH}" || return 1
                    break
                    ;;
                [Nn]* )
                    info "Compose will not be run."
                    return
                    ;;
                * )
                    error "Please answer yes or no."
                    ;;
            esac
        done
        echo
    fi
}
