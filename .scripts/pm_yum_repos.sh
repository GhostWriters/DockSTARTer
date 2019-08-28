#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

pm_yum_repos() {
    info "Installing EPEL and IUS repositories."
    local GET_IUS
    GET_IUS=$(mktemp) || fatal "Failed to create temporary IUS repo install script."
    info "Downloading IUS install script."
    curl -fsSL setup.ius.io -o "${GET_IUS}" > /dev/null 2>&1 || fatal "Failed to get IUS install script."
    info "Running IUS install script."
    local REDIRECT="> /dev/null 2>&1"
    if [[ -n ${VERBOSE:-} ]] || run_script 'question_prompt' "${PROMPT:-}" N "Would you like to display the command output?"; then
        REDIRECT=""
    fi
    eval bash "${GET_IUS}" "${REDIRECT}" || warn "Failed to install IUS."
    rm -f "${GET_IUS}" || warn "Failed to remove temporary IUS repo install script."
}

test_pm_yum_repos() {
    # run_script 'pm_yum_repos'
    warn "CI does not test pm_yum_repos."
}
