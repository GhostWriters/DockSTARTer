#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_yum_repos() {
    local Title="Update Repositories"
    notice "Updating repositories. Please be patient, this can take a while."
    local MKTEMP_GET_IUS
    MKTEMP_GET_IUS=$(mktemp) || fatal "Failed to create temporary IUS repo install script.\nFailing command: ${F[C]}mktemp"
    info "Downloading IUS install script."
    curl -fsSL setup.ius.io -o "${MKTEMP_GET_IUS}" > /dev/null 2>&1 || fatal "Failed to get IUS install script.\nFailing command: ${F[C]}curl -fsSL setup.ius.io -o \"${MKTEMP_GET_IUS}\""
    info "Running IUS install script."
    local COMMAND
    local REDIRECT='> /dev/null 2>&1 '
    if run_script 'question_prompt' Y "Would you like to display the command output?" "${Title}" "${VERBOSE:+Y}"; then
        #shellcheck disable=SC2016 # (info): Expressions don't expand in single quotes, use double quotes for that.
        REDIRECT='run_command_dialog "${Title}" "${COMMAND}" "" '
    fi
    COMMAND="sudo bash ${MKTEMP_GET_IUS}"
    eval "${REDIRECT}${COMMAND}" || warn "Failed to install IUS.\nFailing command: ${F[C]}${COMMAND}"
    rm -f "${MKTEMP_GET_IUS}" || warn "Failed to remove temporary IUS repo install script.\nFailing command: ${F[C]}rm -f \"${MKTEMP_GET_IUS}\""
}

test_pm_yum_repos() {
    # run_script 'pm_yum_repos'
    warn "CI does not test pm_yum_repos."
}
