#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

symlink_ds() {
    if [[ ! -L "/usr/local/bin/ds" ]]; then
        info "Creating symbolic link for DockSTARTer."
        ln -s -T "${SCRIPTNAME}" /usr/local/bin/ds
        chmod +x "${SCRIPTNAME}" > /dev/null 2>&1 || fatal "ds must be executable."
        info "DockSTARTer can be run from anywhere with the following command:"
        info "sudo ds"
    fi
}
