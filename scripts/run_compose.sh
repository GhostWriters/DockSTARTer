#!/bin/bash

run_compose () {
    if [[ ${CI} != true ]] && [[ ${TRAVIS} != true ]]; then
        while true; do
            read -rp "Would you like to run your selected containers now? [Yn]" yn
            case $yn in
                [Yy]* ) cd "${SCRIPTPATH}/compose/" || exit 1; docker-compose up -d; cd "${SCRIPTPATH}" || exit 1; break;;
                [Nn]* ) exit;;
                * ) echo "Please answer yes or no.";;
            esac
        done
    fi
}
