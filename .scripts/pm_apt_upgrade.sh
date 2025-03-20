#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_apt_upgrade() {
    local Title="Upgrade Packages"
    if [[ ${CI-} != true ]]; then
        notice "Upgrading packages. Please be patient, this can take a while."
        local DIALOG_COMMAND="COMMAND"
        local COMMAND='sudo apt-get -y dist-upgrade'
        local REDIRECT="> /dev/null 2>&1"
        if [[ -n ${VERBOSE-} ]] || run_script 'question_prompt' "${PROMPT:-CLI}" N "Would you like to display the command output?" "${Title}"; then
            if [[ ${PROMPT:-CLI} == CLI ]]; then
                REDIRECT=""
            else
                REDIRECT="| dialog --fb --clear --backtitle \"${BACKTITLE}\" --title \"${Title}\" --programbox \"${!DIALOG_COMMAND}\" -1 -1"
            fi
        fi
        eval "${COMMAND} ${REDIRECT}" || fatal "Failed to upgrade packages from apt.\nFailing command: ${F[C]}${COMMAND}"
    fi
}

test_pm_apt_upgrade() {
    run_script 'pm_apt_upgrade'
}
