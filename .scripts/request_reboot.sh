#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

request_reboot() {
    local QUESTION
    QUESTION="Your system needs to reboot for changes to take effect. Would you like to reboot now?"
    info "${QUESTION}"
    local YN
    while true; do
        if [[ ${CI:-} == true ]] && [[ ${TRAVIS:-} == true ]]; then
            info "Travis will not run this."
            return
        elif [[ ${PROMPT:-} == "menu" ]]; then
            local ANSWER
            set +e
            ANSWER=$(
                whiptail --fb --clear --title "DockSTARTer" --yesno "${QUESTION}" 0 0 3>&1 1>&2 2>&3
                echo $?
            )
            set -e
            if [[ ${ANSWER} == 0 ]]; then
                YN=Y
            else
                YN=N
            fi
        else
            read -rp "[Yn]" YN
        fi
        case ${YN} in
            [Yy]*)
                sudo reboot || error "Failed to reboot!"
                break
                ;;
            [Nn]*)
                info "Your system will not reboot."
                warning "If this is your first run the installation will fail."
                warning "Please run the installation again and choose Yes to reboot at the end."
                info "If this is not your first run you may disregard this message."
                return 1
                ;;
            *)
                error "Please answer yes or no."
                ;;
        esac
    done
}
