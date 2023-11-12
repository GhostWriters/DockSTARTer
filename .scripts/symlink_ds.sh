#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

symlink_ds() {
    run_script 'set_permissions' "${SCRIPTNAME}"

    # /usr/bin/ds
    if [[ -L "/usr/bin/ds" ]] && [[ ${SCRIPTNAME} != "$(readlink -f /usr/bin/ds)" ]]; then
        info "Attempting to remove /usr/bin/ds symlink."
        sudo rm -f "/usr/bin/ds" || fatal "Failed to remove file.\nFailing command: ${F[C]}sudo rm -f \"/usr/bin/ds\""
    fi
    if [[ ! -L "/usr/bin/ds" ]]; then
        info "Creating /usr/bin/ds symbolic link for DockSTARTer."
        sudo ln -s -T "${SCRIPTNAME}" /usr/bin/ds || fatal "Failed to create symlink.\nFailing command: ${F[C]}sudo ln -s -T \"${SCRIPTNAME}\" /usr/bin/ds"
    fi

    # /usr/local/bin/ds
    if [[ -L "/usr/local/bin/ds" ]] && [[ ${SCRIPTNAME} != "$(readlink -f /usr/local/bin/ds)" ]]; then
        info "Attempting to remove /usr/local/bin/ds symlink."
        sudo rm -f "/usr/local/bin/ds" || fatal "Failed to remove file.\nFailing command: ${F[C]}sudo rm -f \"/usr/local/bin/ds\""
    fi
    if [[ ! -L "/usr/local/bin/ds" ]]; then
        info "Creating /usr/local/bin/ds symbolic link for DockSTARTer."
        sudo ln -s -T "${SCRIPTNAME}" /usr/local/bin/ds || fatal "Failed to create symlink.\nFailing command: ${F[C]}sudo ln -s -T \"${SCRIPTNAME}\" /usr/local/bin/ds"
    fi
}

test_symlink_ds() {
    run_script 'symlink_ds'
}
