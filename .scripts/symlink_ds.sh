#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

symlink_ds() {
    run_script 'set_permissions' "${SCRIPTNAME}"

    local SYMLINK_TARGETS=("/usr/bin/${APPLICATION_COMMAND}" "/usr/local/bin/${APPLICATION_COMMAND}")

    if findmnt -n /usr | grep -P "\bro\b" > /dev/null; then
        SYMLINK_TARGETS=("${HOME}/bin/${APPLICATION_COMMAND}" "${HOME}/.local/bin/${APPLICATION_COMMAND}")
    fi

    for SYMLINK_TARGET in "${SYMLINK_TARGETS[@]}"; do
        if [[ -L ${SYMLINK_TARGET} ]] && [[ ${SCRIPTNAME} != "$(readlink -f "${SYMLINK_TARGET}")" ]]; then
            info "Attempting to remove '${C["File"]}${SYMLINK_TARGET}${NC}' symlink."
            sudo rm -f "${SYMLINK_TARGET}" || fatal "Failed to remove file.\nFailing command: ${C["FailingCommand"]}sudo rm -f \"${SYMLINK_TARGET}\""
        fi
        if [[ ! -L ${SYMLINK_TARGET} ]]; then
            info "Creating '${C["File"]}${SYMLINK_TARGET}${NC}' symbolic link for ${APPLICATION_NAME}."
            mkdir -p "$(dirname "${SYMLINK_TARGET}")" || fatal "Failed to create directory.\nFailing command: ${C["FailingCommand"]}mkdir -p \"$(dirname "${SYMLINK_TARGET}")\""
            sudo ln -s -T "${SCRIPTNAME}" "${SYMLINK_TARGET}" || fatal "Failed to create symlink.\nFailing command: ${C["FailingCommand"]}sudo ln -s -T \"${SCRIPTNAME}\" \"${SYMLINK_TARGET}\""
        fi
        if [[ ${PATH} != *"$(dirname "${SYMLINK_TARGET}")"* ]]; then
            warn "'${C["File"]}$(dirname "${SYMLINK_TARGET}")${NC}' not found in '${C["Var"]}PATH${NC}'. Please add it to your '${C["Var"]}PATH${NC}' in order to use the '${C["UserCommand"]}${APPLICATION_COMMAND}${NC}' command alias."
        fi
    done
}

test_symlink_ds() {
    run_script 'symlink_ds'
}
