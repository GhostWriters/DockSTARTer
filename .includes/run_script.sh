#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

# Script Runner Function
run_script() {
    local SCRIPTSNAME=${1-}
    shift
    if [[ -f ${SCRIPTPATH}/.scripts/${SCRIPTSNAME}.sh ]]; then
        # shellcheck source=/dev/null
        source "${SCRIPTPATH}/.scripts/${SCRIPTSNAME}.sh"
        ${SCRIPTSNAME} "$@"
        return
    else
        fatal "'${C["File"]}${SCRIPTPATH}/.scripts/${SCRIPTSNAME}.sh${NC}' not found."
    fi
}
