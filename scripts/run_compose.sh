#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

run_compose() {
    local PROMPT
    PROMPT=${1:-}
    local QUESTION
    QUESTION="Would you like to run your selected containers now?"
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
                run_script 'install_docker'
                run_script 'install_compose'
                local PUID
                PUID=$(run_script 'env_get' PUID)
                local PGID
                PGID=$(run_script 'env_get' PGID)
                run_script 'set_permissions' "${SCRIPTPATH}" "${PUID}" "${PGID}"
                cd "${SCRIPTPATH}/compose/" || return 1
                docker-compose up -d
                cd "${SCRIPTPATH}" || return 1
                break
                ;;
            [Nn]* )
                info "Compose will not be run."
                return
                ;;
            * )
                error "Please answer yes or no."
                ;;
        esac
    done
}
