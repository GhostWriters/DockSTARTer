#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

update_system() {
    if [[ -n "$(command -v apt-get)" ]]; then
        info "APT package manager detectec."
        run_script 'run_apt'
    elif [[ -n "$(command -v dnf)" ]]; then
        info "DNF package manager detectec."
        run_script 'run_dnf'
    elif [[ -n "$(command -v yum)" ]]; then
        info "YUM package manager detectec."
        run_script 'run_yum'
    else
        fatal "Package manager not detected!"
    fi
}
