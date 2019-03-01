#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

update_system() {
    if [[ -n "$(command -v apt-get)" ]]; then
        info "apt package manager detected."
        run_script 'run_apt'
    elif [[ -n "$(command -v dnf)" ]]; then
        info "dnf package manager detected."
        run_script 'run_dnf'
    elif [[ -n "$(command -v yum)" ]]; then
        info "yum package manager detected."
        run_script 'run_yum'
    else
        fatal "Package manager not detected!"
    fi
}

test_update_system() {
    run_script 'update_system'
}
