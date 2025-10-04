#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_yum_upgrade() {
    #shellcheck disable=SC2034 #(warning): Title appears unused. Verify use (or export if used externally).
    local Title="Upgrade Packages"
    if [[ ${CI-} != true ]]; then
        notice "Upgrading packages. Please be patient, this can take a while."
        local COMMAND='sudo yum -y upgrade'
        local REDIRECT='> /dev/null 2>&1 '
        if [[ -n ${VERBOSE-} ]]; then
            #shellcheck disable=SC2016 # (info): Expressions don't expand in single quotes, use double quotes for that.
            REDIRECT='run_command_dialog "${Title}" "${COMMAND}" "" '
        fi
        eval "${REDIRECT}${COMMAND}" || fatal "Failed to upgrade packages from yum.\nFailing command: ${C["FailingCommand"]}${COMMAND}"
    fi
}

test_pm_yum_upgrade() {
    # run_script 'pm_yum_upgrade'
    warn "CI does not test pm_yum_upgrade."
}
