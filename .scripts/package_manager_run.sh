#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

package_manager_run() {
    local ACTION=${1:-}
    if [[ -n "$(command -v apt-get)" ]]; then
        run_script "pm_apt_${ACTION}"
    elif [[ -n "$(command -v dnf)" ]]; then
        run_script "pm_dnf_${ACTION}"
    elif [[ -n "$(command -v yum)" ]]; then
        run_script "pm_yum_${ACTION}"
    elif [[ -n "$(command -v pacman)" ]]; then
        warn "Arch Linux based distributions are not officially supported."
        warn "You will need to install docker and docker-compose manually."
    else
        fatal "Package manager not detected!"
    fi
}

test_package_manager_run() {
    run_script 'package_manager_run' clean
}
