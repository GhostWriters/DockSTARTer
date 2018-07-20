#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

request_reboot() {
    local PROMPT
    PROMPT=${1:-}
    local QUESTION
    QUESTION="Your system needs to reboot for changes to take effect. Would you like to reboot now?"
    info "${QUESTION}"
    local YN
    while true; do
        if [[ ${CI:-} == true ]] && [[ ${TRAVIS:-} == true ]]; then
            YN=N
        elif [[ ${PROMPT} == "menu" ]]; then
            local ANSWER
            set +e
            ANSWER=$(whiptail --fb --yesno "${QUESTION}" 0 0 3>&1 1>&2 2>&3; echo $?)
            set -e
            [[ ${ANSWER} == 0 ]] && YN=Y || YN=N
        else
            read -rp "[Yn]" YN
        fi
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
}
