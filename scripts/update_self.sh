#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

update_self() {
    local PROMPT
    PROMPT=${1:-}
    local QUESTION
    QUESTION="Would you like to update DockSTARTer now?"
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
                info "Updating DockSTARTer."
                git -C "${SCRIPTPATH}" fetch --all > /dev/null 2>&1
                git -C "${SCRIPTPATH}" reset --hard origin/master > /dev/null 2>&1
                break
                ;;
            [Nn]* )
                info "DockSTARTer will not be updated."
                return
                ;;
            * )
                error "Please answer yes or no."
                ;;
        esac
    done
}
