#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

symlink_ds() {
    run_script 'set_permissions' "${SCRIPTNAME}"

    if findmnt -n /usr | grep "ro" > /dev/null; then
        if [[ $PATH != *"$HOME/bin"* ]]; then
            warn "Read only /usr filesystem detected. Symlinks will be created in $HOME/bin. You will need to add this to your path."
        fi
        mkdir -p "$HOME/bin" # Make sure the path exists.
        DS_SYMLINK_TARGETS=("HOME/bin")
    else
        DS_SYMLINK_TARGETS=("/usr/bin/ds" "/usr/local/bin/ds")
    fi

    for DS_SYMLINK_TARGET in "${DS_SYMLINK_TARGETS[@]}"; do
        if [[ -L ${DS_SYMLINK_TARGET} ]] && [[ ${SCRIPTNAME} != "$(readlink -f "${target}")" ]]; then
            info "Attempting to remove ${DS_SYMLINK_TARGET} symlink."
            sudo rm -f "${target}" || fatal "Failed to remove file.\nFailing command: ${F[C]}sudo rm -f \"${target}\""
        fi
        if [[ ! -L ${target} ]]; then
            info "Creating ${target} symbolic link for DockSTARTer."
            sudo ln -s -T "${SCRIPTNAME}" "${target}" || fatal "Failed to create symlink.\nFailing command: ${F[C]}sudo ln -s -T \"${SCRIPTNAME}\" \"${target}\""
        fi
    done
}

test_symlink_ds() {
    run_script 'symlink_ds'
}
