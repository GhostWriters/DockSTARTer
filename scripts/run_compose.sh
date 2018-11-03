#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

run_compose() {
    local UPDOWN
    UPDOWN=${1:-up}
    local QUESTION
    if [[ $UPDOWN == "up" ]]; then
        QUESTION="Would you like to run your selected containers now?"
        UPDOWN="up -d"
    else
        QUESTION="Containers will be stopped and removed."
    fi
    info "${QUESTION}"
    local YN
    while true; do
        if [[ $UPDOWN == "down" ]]; then
            YN=Y
        elif [[ ${CI:-} == true ]] && [[ ${TRAVIS:-} == true ]]; then
            info "Travis will not run this."
            return
        elif [[ ${PROMPT:-} == "menu" ]]; then
            local ANSWER
            set +e
            ANSWER=$(whiptail --fb --clear --title "DockSTARTer" --yesno "${QUESTION}" 0 0 3>&1 1>&2 2>&3; echo $?)
            set -e
            [[ ${ANSWER} == 0 ]] && YN=Y || YN=N
        else
            read -rp "[Yn]" YN
        fi
        case ${YN} in
            [Yy]*)
                run_script 'install_docker'
                run_script 'install_compose'
                local PUID
                PUID=$(run_script 'env_get' PUID)
                local PGID
                PGID=$(run_script 'env_get' PGID)
                run_script 'set_permissions' "${SCRIPTPATH}" "${PUID}" "${PGID}"
                cd "${SCRIPTPATH}/compose/" || fatal "Failed to change directory to ${SCRIPTPATH}/compose/"
                su "${DETECTED_UNAME}" -c "docker-compose ${UPDOWN} --remove-orphans" || fatal "Docker Compose failed."
                cd "${SCRIPTPATH}" || fatal "Failed to change directory to ${SCRIPTPATH}"
                break
                ;;
            [Nn]*)
                info "Compose will not be run."
                return 1
                ;;
            *)
                error "Please answer yes or no."
                ;;
        esac
    done
}
