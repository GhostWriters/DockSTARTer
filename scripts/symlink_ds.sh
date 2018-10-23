#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

symlink_ds() {
    if [[ -L "/usr/local/bin/ds" ]] && [[ ${SCRIPTNAME} != "$(readlink -f /usr/local/bin/ds)" ]]; then
        info "Attempting to remove ds symlink found at /usr/local/bin/ds"
        rm "/usr/local/bin/ds" || fatal "Failed to remove /usr/local/bin/ds"
    fi
    if [[ ! -L "/usr/local/bin/ds" ]]; then
        info "Creating symbolic link for DockSTARTer."
        ln -s -T "${SCRIPTNAME}" /usr/local/bin/ds || fatal "Failed to create ds symlink."
        chmod +x "${SCRIPTNAME}" > /dev/null 2>&1 || fatal "ds must be executable."
        info "DockSTARTer can be run from anywhere with the following command:"
        info "sudo ds"
    fi
}
