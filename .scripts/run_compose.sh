#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

run_compose() {
    local COMPOSECOMMAND
    COMPOSECOMMAND=${1:-}
    local FORCE
    local QUESTION
    case ${COMPOSECOMMAND} in
        down)
            COMPOSECOMMAND="down --remove-orphans"
            FORCE=Y
            QUESTION="Stoping and removing containers, networks, volumes, and images created by DockSTARTer."
            ;;
        pull)
            COMPOSECOMMAND="pull --include-deps"
            FORCE=Y
            QUESTION="Pulling the latest images for all enabled services."
            ;;
        restart)
            COMPOSECOMMAND="restart"
            FORCE=Y
            QUESTION="Restarting all stopped and running services."
            ;;
        up)
            COMPOSECOMMAND="up -d --remove-orphans"
            FORCE=Y
            QUESTION="Creating containers for all enabled services."
            ;;
        *)
            COMPOSECOMMAND="up -d --remove-orphans"
            FORCE=N
            QUESTION="Would you like to create containers for all enabled services now?"
            ;;
    esac
    info "${QUESTION}"
    local YN
    while true; do
        if [[ ${FORCE} != "Y" ]]; then
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
        else
            YN=Y
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
                su "${DETECTED_UNAME}" -c "docker-compose ${COMPOSECOMMAND}" || fatal "Docker Compose failed."
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
