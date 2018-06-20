#!/bin/bash

update_self () {
    if [[ ${CI} != true ]] && [[ ${TRAVIS} != true ]]; then
        echo
        while true; do
            read -rp "Would you like to update DockSTARTer now? [Yn]" yn
            case $yn in
                [Yy]* )
                    git -C "${SCRIPTPATH}" fetch --all
                    git -C "${SCRIPTPATH}" reset --hard origin/master
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
