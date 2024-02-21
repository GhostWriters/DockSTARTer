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
        DS_SYMLINK_TARGETS=("$HOME/bin")
    else
        DS_SYMLINK_TARGETS=("/usr/bin/ds" "/usr/local/bin/ds")
    fi

    for DS_SYMLINK_TARGET in "${DS_SYMLINK_TARGETS[@]}"; do
        if [[ -L ${DS_SYMLINK_TARGET} ]] && [[ ${SCRIPTNAME} != "$(readlink -f "${DS_SYMLINK_TARGET}")" ]]; then
            info "Attempting to remove ${DS_SYMLINK_TARGET} symlink."
            sudo rm -f "${DS_SYMLINK_TARGET}" || fatal "Failed to remove file.\nFailing command: ${F[C]}sudo rm -f \"${DS_SYMLINK_TARGET}\""
        fi
        if [[ ! -L ${DS_SYMLINK_TARGET} ]]; then
            info "Creating ${DS_SYMLINK_TARGET} symbolic link for DockSTARTer."
            sudo ln -s -T "${SCRIPTNAME}" "${DS_SYMLINK_TARGET}" || fatal "Failed to create symlink.\nFailing command: ${F[C]}sudo ln -s -T \"${SCRIPTNAME}\" \"${DS_SYMLINK_TARGET}\""
        fi
    done
}

test_symlink_ds() {
    run_script 'symlink_ds'
}
