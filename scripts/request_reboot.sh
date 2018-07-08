#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

request_reboot() {
    if [[ ${CI:-} != true ]] && [[ ${TRAVIS:-} != true ]]; then
        echo
        info "Your system needs to reboot for changes to take effect. Would you like to reboot now?"
        local YN
        while true; do
            read -rp "[Yn]" YN
            case ${YN} in
                [Yy]* )
                    sudo reboot
                    break
                    ;;
                [Nn]* )
                    info "Your system will not reboot."
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
