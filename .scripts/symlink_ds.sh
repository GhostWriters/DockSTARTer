#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

symlink_ds() {
    # /usr/bin/ds
    if [[ -L "/usr/bin/ds" ]] && [[ ${SCRIPTNAME} != "$(readlink -f /usr/bin/ds)" ]]; then
        info "Attempting to remove /usr/bin/ds symlink."
        rm "/usr/bin/ds" || fatal "Failed to remove /usr/bin/ds"
    fi
    if [[ ! -L "/usr/bin/ds" ]]; then
        info "Creating /usr/bin/ds symbolic link for DockSTARTer."
        ln -s -T "${SCRIPTNAME}" /usr/bin/ds || fatal "Failed to create /usr/bin/ds symlink."
    fi

    # /usr/local/bin/ds
    if [[ -L "/usr/local/bin/ds" ]] && [[ ${SCRIPTNAME} != "$(readlink -f /usr/local/bin/ds)" ]]; then
        info "Attempting to remove /usr/local/bin/ds symlink."
        rm "/usr/local/bin/ds" || fatal "Failed to remove /usr/local/bin/ds"
    fi
    if [[ ! -L "/usr/local/bin/ds" ]]; then
        info "Creating /usr/local/bin/ds symbolic link for DockSTARTer."
        ln -s -T "${SCRIPTNAME}" /usr/local/bin/ds || fatal "Failed to create /usr/local/bin/ds symlink."
    fi
}

test_symlink_ds() {
    run_script 'symlink_ds'
}
