#!/bin/bash

run_compose() {
    if [[ ${CI} != true ]] && [[ ${TRAVIS} != true ]]; then
        echo
        local YN
        while true; do
            read -rp "Would you like to run your selected containers now? [Yn]" YN
            case ${YN} in
                [Yy]* )
                    cd "${SCRIPTPATH}/compose/" || return 1
                    docker-compose up -d
                    cd "${SCRIPTPATH}" || return 1
                    break
                    ;;
                [Nn]* )
                    return
                    ;;
                * )
                    echo "Please answer yes or no."
                    ;;
            esac
        done
        echo
    fi
}
