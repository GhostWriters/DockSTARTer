#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_yum_repos() {
    notice "Updating repositories. Please be patient, this can take a while."
    local MKTEMP_GET_IUS
    MKTEMP_GET_IUS=$(mktemp) || fatal "Failed to create temporary IUS repo install script.\nFailing command: ${F[C]}mktemp"
    info "Downloading IUS install script."
    curl -fsSL setup.ius.io -o "${MKTEMP_GET_IUS}" > /dev/null 2>&1 || fatal "Failed to get IUS install script.\nFailing command: ${F[C]}curl -fsSL setup.ius.io -o \"${MKTEMP_GET_IUS}\""
    info "Running IUS install script."
    local REDIRECT="> /dev/null 2>&1"
    if [[ -n ${VERBOSE-} ]] || run_script 'question_prompt' "${PROMPT:-CLI}" N "Would you like to display the command output?"; then
        REDIRECT=""
    fi
    eval "sudo bash ${MKTEMP_GET_IUS} ${REDIRECT}" || warn "Failed to install IUS.\nFailing command: ${F[C]}sudo bash ${MKTEMP_GET_IUS}"
    rm -f "${MKTEMP_GET_IUS}" || warn "Failed to remove temporary IUS repo install script.\nFailing command: ${F[C]}rm -f \"${MKTEMP_GET_IUS}\""
}

test_pm_yum_repos() {
    # run_script 'pm_yum_repos'
    warn "CI does not test pm_yum_repos."
}
