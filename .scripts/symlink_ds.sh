#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

symlink_ds() {
    run_script 'set_permissions' "${SCRIPTNAME}"

    local -a SYMLINK_FOLDERS=(
        "/usr/bin"
        "/usr/local/bin"
        "${HOME}/bin"
        "${HOME}/.local/bin"
    )

    local FINAL_SYMLINK_FOLDER=''
    for SYMLINK_FOLDER in "${SYMLINK_FOLDERS[@]}"; do
        local SYMLINK_TARGET="${SYMLINK_FOLDER}/${APPLICATION_COMMAND}"
        if [[ -L ${SYMLINK_TARGET} ]] && [[ ${SCRIPTNAME} != "$(readlink -f "${SYMLINK_TARGET}")" ]]; then
            info "Attempting to remove '${C["File"]}${SYMLINK_TARGET}${NC}' symlink."
            sudo rm -f "${SYMLINK_TARGET}" &> /dev/null || true
        fi
        if [[ ! -L ${SYMLINK_TARGET} ]]; then
            info "Creating '${C["File"]}${SYMLINK_TARGET}${NC}' symbolic link for ${APPLICATION_NAME}."
            mkdir -p "${SYMLINK_FOLDER}" &> /dev/null || true
            sudo ln -s -F "${SCRIPTNAME}" "${SYMLINK_TARGET}" &> /dev/null || true
        fi
        if [[ -L ${SYMLINK_TARGET} ]]; then
            FINAL_SYMLINK_FOLDER="${SYMLINK_FOLDER}"
            break
        fi
    done
    if [[ -n ${FINAL_SYMLINK_FOLDER} ]]; then
        if [[ ":${PATH}:" != *":${FINAL_SYMLINK_FOLDER}:"* ]]; then
            warn "'${C["File"]}${FINAL_SYMLINK_FOLDER}${NC}' not found in '${C["Var"]}PATH${NC}'. Please add it to your '${C["Var"]}PATH${NC}' in order to use the '${C["UserCommand"]}${APPLICATION_COMMAND}${NC}' command alias."
        fi
    else
        fatal "Failed to create symlink."
    fi
}

test_symlink_ds() {
    run_script 'symlink_ds'
}
