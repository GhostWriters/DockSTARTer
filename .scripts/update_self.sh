#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

update_self() {
    local BRANCH
    BRANCH=${1:-}
    local QUESTION
    QUESTION="Would you like to update DockSTARTer to ${BRANCH} now?"
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
                cd "${SCRIPTPATH}" || fatal "Failed to change to ${SCRIPTPATH} directory."
                git fetch > /dev/null 2>&1 || fatal "Failed to fetch recent changes from git."
                git reset --hard "${BRANCH}" > /dev/null 2>&1 || fatal "Failed to reset to ${BRANCH}."
                git pull > /dev/null 2>&1 || fatal "Failed to pull recent changes from git."
                git for-each-ref --format '%(refname:short)' refs/heads | grep -v master | xargs git branch -D || true
                chmod +x "${SCRIPTNAME}" > /dev/null 2>&1 || fatal "ds must be executable."
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
