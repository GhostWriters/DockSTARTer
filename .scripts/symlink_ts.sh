#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

symlink_ts() {
    run_script 'set_permissions' "${SCRIPTNAME}"

    # /usr/bin/ts
    if [[ -L "/usr/bin/ts" ]] && [[ ${SCRIPTNAME} != "$(readlink -f /usr/bin/ts)" ]]; then
        info "Attempting to remove /usr/bin/ts symlink."
        rm -f "/usr/bin/ts" || fatal "Failed to remove file.\nFailing command: ${F[C]}rm -f \"/usr/bin/ts\""
    fi
    if [[ ! -L "/usr/bin/ts" ]]; then
        info "Creating /usr/bin/ts symbolic link for TrunkSTARTer."
        ln -s -T "${SCRIPTNAME}" /usr/bin/ts || fatal "Failed to create symlink.\nFailing command: ${F[C]}ln -s -T \"${SCRIPTNAME}\" /usr/bin/ts"
    fi

    # /usr/local/bin/ts
    if [[ -L "/usr/local/bin/ts" ]] && [[ ${SCRIPTNAME} != "$(readlink -f /usr/local/bin/ts)" ]]; then
        info "Attempting to remove /usr/local/bin/ds symlink."
        rm -f "/usr/local/bin/ts" || fatal "Failed to remove file.\nFailing command: ${F[C]}rm -f \"/usr/local/bin/ts\""
    fi
    if [[ ! -L "/usr/local/bin/ts" ]]; then
        info "Creating /usr/local/bin/ts symbolic link for TrunkSTARTer."
        ln -s -T "${SCRIPTNAME}" /usr/local/bin/ts || fatal "Failed to create symlink.\nFailing command: ${F[C]}ln -s -T \"${SCRIPTNAME}\" /usr/local/bin/ts"
    fi
}

test_symlink_ts() {
    run_script 'symlink_ts'
}
