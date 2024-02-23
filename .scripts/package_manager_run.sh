#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

package_manager_run() {
    local ACTION=${1-}
    if [[ -n "$(command -v apk)" ]]; then
        run_script "pm_apk_${ACTION}"
    elif [[ -n "$(command -v apt-get)" ]]; then
        run_script "pm_apt_${ACTION}"
    elif [[ -n "$(command -v dnf)" ]]; then
        run_script "pm_dnf_${ACTION}"
    elif [[ -n "$(command -v pacman)" ]]; then
        run_script "pm_pacman_${ACTION}"
    elif [[ -n "$(command -v yum)" ]]; then
        run_script "pm_yum_${ACTION}"
    else
        if [[ ${ACTION} == "install" ]]; then
            local COMMAND_DEPS=("curl" "git" "grep" "sed" "whiptail")
            for COMMAND_DEP in "${COMMAND_DEPS[@]}"; do
                if [[ -z "$(command -v "${COMMAND_DEP}")" ]]; then
                    fatal "${F[C]}${COMMAND_DEP}${NC} is not available. Please install ${F[C]}${COMMAND_DEP}${NC} and try again."
                fi
            done
        elif [[ ${ACTION} == "install_docker" ]]; then
            if [[ -z "$(command -v docker)" ]]; then
                fatal "${F[C]}docker${NC} is not available. Please install ${F[C]}docker${NC} and try again."
            fi
            if ! docker compose version > /dev/null 2>&1; then
                warn "Please see https://docs.docker.com/compose/install/linux/ to install ${F[C]}docker compose${NC}"
                fatal "${F[C]}docker compose${NC} is not available. Please install ${F[C]}docker compose${NC} and try again."
            fi
        fi
    fi
}

test_package_manager_run() {
    run_script 'package_manager_run' clean
}
