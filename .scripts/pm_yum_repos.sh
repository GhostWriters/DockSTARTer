#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_yum_repos() {
    #shellcheck disable=SC2034 #(warning): Title appears unused. Verify use (or export if used externally).
    local Title="Update Repositories"
    notice "Updating repositories. Please be patient, this can take a while."
    local MKTEMP_GET_IUS
    MKTEMP_GET_IUS=$(mktemp -t "${APPLICATION_NAME}.${FUNCNAME[0]}.MKTEMP_GET_IUS.XXXXXXXXXX") ||
        fatal \
            "Failed to create temporary IUS repo install script.\n" \
            "Failing command: ${C["FailingCommand"]}mktemp -t \"${APPLICATION_NAME}.${FUNCNAME[0]}.MKTEMP_GET_IUS.XXXXXXXXXX\""
    info "Downloading IUS install script."
    curl -fsSL setup.ius.io -o "${MKTEMP_GET_IUS}" &> /dev/null ||
        fatal \
            "Failed to get IUS install script.\n" \
            "Failing command: ${C["FailingCommand"]}curl -fsSL setup.ius.io -o \"${MKTEMP_GET_IUS}\""

    info "Running IUS install script."
    local COMMAND
    local REDIRECT='&> /dev/null '
    if [[ -n ${VERBOSE-} ]]; then
        #shellcheck disable=SC2016 # (info): Expressions don't expand in single quotes, use double quotes for that.
        REDIRECT='run_command_dialog "${Title}" "${COMMAND}" "" '
    fi
    COMMAND="sudo bash ${MKTEMP_GET_IUS}"
    eval "${REDIRECT}${COMMAND}" ||
        warn \
            "Failed to install IUS.\n" \
            "Failing command: ${C["FailingCommand"]}${COMMAND}"
    rm -f "${MKTEMP_GET_IUS}" ||
        warn \
            "Failed to remove temporary IUS repo install script.\n" \
            "Failing command: ${C["FailingCommand"]}rm -f \"${MKTEMP_GET_IUS}\""
}

test_pm_yum_repos() {
    # run_script 'pm_yum_repos'
    warn "CI does not test pm_yum_repos."
}
