#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_apt_upgrade() {
    local Title="Upgrade Packages"
    if [[ ${CI-} != true ]]; then
        notice "Upgrading packages. Please be patient, this can take a while."
        local COMMAND='sudo apt-get -y dist-upgrade'
        local REDIRECT="> /dev/null 2>&1"
        if run_script 'question_prompt' Y "Would you like to display the command output?" "${Title}" "${VERBOSE:+Y}"; then
            if use_dialog_box; then
                run_command_dialog "${Title}" "${COMMAND}" "" eval "${COMMAND}" || fatal "Failed to upgrade packages from apt.\nFailing command: ${F[C]}${COMMAND}"
                return
            else
                REDIRECT=""
            fi
        fi
        eval "${COMMAND} ${REDIRECT}" || fatal "Failed to upgrade packages from apt.\nFailing command: ${F[C]}${COMMAND}"
    fi
}

test_pm_apt_upgrade() {
    run_script 'pm_apt_upgrade'
}
