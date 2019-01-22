#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

update_self() {
    local QUESTION
    QUESTION="Would you like to update DockSTARTer now?"
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
                info "Updating DockSTARTer."
                run_cmd cd "${SCRIPTPATH}" || fatal "Failed to change to ${SCRIPTPATH} directory."
                run_cmd git fetch --all || fatal "Failed to fetch recent changes from git."
                run_cmd git reset --hard origin/master || fatal "Failed to reset to master."
                run_cmd git pull || fatal "Failed to pull recent changes from git."
                run_cmd chmod +x "${SCRIPTNAME}" || fatal "ds must be executable."
                run_script 'env_update'
                break
                ;;
            [Nn]*)
                info "DockSTARTer will not be updated."
                return 1
                ;;
            *)
                error "Please answer yes or no."
                ;;
        esac
    done
}
