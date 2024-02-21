#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

symlink_ds() {
    run_script 'set_permissions' "${SCRIPTNAME}"

    if findmnt -n /usr | grep "ro" > /dev/null; then
        if [[ "$PATH" != *"$HOME/bin"* ]]; then
            warn "Read only /usr filesystem detected. Symlinks will be created in $HOME/bin. You will need to add this to your path."
        fi
        mkdir -p "$HOME/bin" # Make sure the path exists.
        ds_symlink_targets=("HOME/bin")
    else
        ds_symlink_targets=("/usr/bin/ds" "/usr/local/bin/ds")
    fi

    for target in "${ds_symlink_targets[@]}"; do
        if [[ -L "${target}" ]] && [[ "${SCRIPTNAME}" != "$(readlink -f "${target}")" ]]; then
            info "Attempting to remove ${target} symlink."
            sudo rm -f "${target}" || fatal "Failed to remove file. Failing command: sudo rm -f \"${target}\""
        fi
        if [[ ! -L "${target}" ]]; then
            info "Creating ${target} symbolic link for DockSTARTer."
            sudo ln -s -T "${SCRIPTNAME}" "${target}" || fatal "Failed to create symlink. Failing command: sudo ln -s -T \"${SCRIPTNAME}\" \"${target}\""
        fi
    done
}

test_symlink_ds() {
    run_script 'symlink_ds'
}
