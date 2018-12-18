#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

prune_docker() {
    local QUESTION
    QUESTION="Would you like to remove all unused containers, networks, volumes, images and build cache?"
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
                docker system prune -a --volumes --force || error "Failed to prune unused docker resources."
                break
                ;;
            [Nn]*)
                info "Nothing will be removed."
                return 1
                ;;
            *)
                error "Please answer yes or no."
                ;;
        esac
    done
}
