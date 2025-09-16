#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

# Test Runner Function
run_test() {
    local SCRIPTSNAME=${1-}
    shift
    local TESTSNAME="test_${SCRIPTSNAME}"
    if [[ -f ${SCRIPTPATH}/.scripts/${SCRIPTSNAME}.sh ]]; then
        if grep -q -P "${TESTSNAME}" "${SCRIPTPATH}/.scripts/${SCRIPTSNAME}.sh"; then
            notice "Testing '${C["RunningCommand"]-}${SCRIPTSNAME}${NC-}'."
            # shellcheck source=/dev/null
            source "${SCRIPTPATH}/.scripts/${SCRIPTSNAME}.sh"
            "${TESTSNAME}" "$@" || fatal "Failed to run '${C["FailingCommand"]-}${TESTSNAME}${NC-}'."
            notice "Completed testing '${C["RunningCommand"]-}${TESTSNAME}${NC-}'."
        else
            fatal "Test function in '${C["File"]-}${SCRIPTPATH}/.scripts/${SCRIPTSNAME}.sh${NC-}' not found."
        fi
    else
        fatal "${SCRIPTPATH}/.scripts/${SCRIPTSNAME}.sh not found."
    fi
}
