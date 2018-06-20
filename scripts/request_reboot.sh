#!/bin/bash

request_reboot () {
    if [[ ${CI} != true ]] && [[ ${TRAVIS} != true ]]; then
        echo
        while true; do
            read -rp "Your system needs to reboot for changes to take effect. Would you like to reboot now? [Yn]" yn
            case $yn in
                [Yy]* )
                    sudo reboot;
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
