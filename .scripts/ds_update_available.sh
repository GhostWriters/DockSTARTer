#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

ds_update_available() {
    pushd "${SCRIPTPATH}" &> /dev/null || fatal "Failed to change directory.\nFailing command: ${F[C]}pushd \"${SCRIPTPATH}\""
    git fetch --quiet &> /dev/null
    local -i result=0
    # shellcheck disable=SC2319 # This $? refers to a condition, not a command. Assign to a variable to avoid it being overwritten.
    [[ $(git rev-parse HEAD 2> /dev/null) != $(git rev-parse '@{u}' 2> /dev/null) ]] || result=$?
    popd &> /dev/null
    return ${result}
}

test_ds_update_available() {
    if run_script 'update_available'; then
        notice "Update available."
    else
        notice "DockSTARTer is already up to date."
    fi
}
