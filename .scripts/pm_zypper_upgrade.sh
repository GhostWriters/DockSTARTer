#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_zypper_upgrade() {
    #shellcheck disable=SC2034 #(warning): Title appears unused. Verify use (or export if used externally).
    local Title="Upgrade Packages"
    if [[ ${CI-} != true ]]; then
        notice "Upgrading packages. Please be patient, this can take a while."
        local COMMAND='sudo zypper -n dist-upgrade'
        local REDIRECT='&> /dev/null '
        if [[ -n ${VERBOSE-} ]]; then
            #shellcheck disable=SC2016 # (info): Expressions don't expand in single quotes, use double quotes for that.
            REDIRECT='run_command_dialog "${Title}" "${COMMAND}" "" '
        fi
        eval "${REDIRECT}${COMMAND}" ||
            fatal \
                "Failed to upgrade packages from zypper.\n" \
                "Failing command: ${C["FailingCommand"]}${COMMAND}"
    fi
}

test_pm_zypper_upgrade() {
    # run_script 'pm_zypper_upgrade'
    warn "CI does not test pm_zypper_upgrade."
}
