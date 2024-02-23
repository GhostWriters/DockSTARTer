#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

package_manager_run() {
    local ACTION=${1-}
    if [[ -n "$(command -v apt-get)" ]]; then
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
                if ! command -v "${COMMAND_DEP}" &> /dev/null; then
                    fatal "Error: '${COMMAND_DEP}' is not available. Please install '${COMMAND_DEP}' and try again."
                fi
            done
        elif [[ ${ACTION} == "install_docker" ]]; then
            if ! command -v "docker" &> /dev/null; then
                fatal "Error: 'docker' is not available. Please install 'docker' and try again."
            fi
            if ! docker compose version > /dev/null 2>&1; then
                fatal "Error: 'docker compose' is not available. Please install 'docker compose' and try again."
            fi
        fi
    fi
}

test_package_manager_run() {
    run_script 'package_manager_run' clean
}
