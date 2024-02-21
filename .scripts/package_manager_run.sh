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
    elif [[ ${ACTION} == "install" ]]; then
        # We might not need a supported package manager at all if the dependencies are there already. Let's validate that.

        # Define an array of commands
        commands=("curl" "docker" "git" "grep" "sed" "whiptail")

        # Iterate over each command in the array
        for cmd in "${commands[@]}"; do
            # Check if the command is available in the system
            if ! command -v "$cmd" &> /dev/null; then
                fatal "Error: '$cmd' is not available. Exiting..."
            fi
        done

        if [[ "$(docker compose 2>&1)" == *"docker: 'compose' is not a docker command."* ]]; then
            fatal "The 'docker compose' command is not functional. Follow the directions at https://docs.docker.com/compose/install/linux/ to install compose."
        fi
    fi
}

test_package_manager_run() {
    run_script 'package_manager_run' clean
}
