#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

symlink_ds() {
    run_script 'set_permissions' "${SCRIPTNAME}"

    local SYMLINK_TARGETS=("/usr/bin/ds" "/usr/local/bin/ds")

    if findmnt -n /usr | grep -P "\bro\b" > /dev/null; then
        SYMLINK_TARGETS=("${HOME}/bin/ds" "${HOME}/.local/bin/ds")
    fi

    for SYMLINK_TARGET in "${SYMLINK_TARGETS[@]}"; do
        if [[ -L ${SYMLINK_TARGET} ]] && [[ ${SCRIPTNAME} != "$(readlink -f "${SYMLINK_TARGET}")" ]]; then
            info "Attempting to remove ${SYMLINK_TARGET} symlink."
            sudo rm -f "${SYMLINK_TARGET}" || fatal "Failed to remove file.\nFailing command: ${F[C]}sudo rm -f \"${SYMLINK_TARGET}\""
        fi
        if [[ ! -L ${SYMLINK_TARGET} ]]; then
            info "Creating ${SYMLINK_TARGET} symbolic link for DockSTARTer."
            mkdir -p "$(dirname "${SYMLINK_TARGET}")" || fatal "Failed to create directory.\nFailing command: ${F[C]}mkdir -p \"$(dirname "${SYMLINK_TARGET}")\""
            sudo ln -s -T "${SCRIPTNAME}" "${SYMLINK_TARGET}" || fatal "Failed to create symlink.\nFailing command: ${F[C]}sudo ln -s -T \"${SCRIPTNAME}\" \"${SYMLINK_TARGET}\""
        fi
        if [[ ${PATH} != *"$(dirname "${SYMLINK_TARGET}")"* ]]; then
            warn "${F[C]}$(dirname "${SYMLINK_TARGET}")${NC} not found in PATH. Please add it to your PATH in order to use the ${F[C]}ds${NC} command alias."
        fi
    done
}

test_symlink_ds() {
    run_script 'symlink_ds'
}
