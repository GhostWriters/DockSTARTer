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
            info "Travis will not run this."
            return
        elif [[ ${PROMPT} == "menu" ]]; then
            local ANSWER
            set +e
            ANSWER=$(whiptail --fb --clear --title "DockSTARTer" --yesno "${QUESTION}" 0 0 3>&1 1>&2 2>&3; echo $?)
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
                git -C "${SCRIPTPATH}" pull > /dev/null 2>&1
                chmod +x "${SCRIPTNAME}" > /dev/null 2>&1 || fatal "ds must be executable."
                run_script 'env_update'
                break
                ;;
            [Nn]* )
                info "DockSTARTer will not be updated."
                return 1
                ;;
            * )
                error "Please answer yes or no."
                ;;
        esac
    done
}
