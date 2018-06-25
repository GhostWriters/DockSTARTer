#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

validate_shellcheck() {
    shellcheck -V

    # Check for Shellcheck errors in the code.
    local SCERRORS
    SCERRORS=$(find . -name '*.sh' -print0 | xargs -0 shellcheck -e SC1090 -e SC1091 -e SC2034)
    if [[ -n ${SCERRORS} ]]; then
        error "Shellcheck error found"
        find . -name '*.sh' -print0 | xargs -0 shellcheck -e SC1090 -e SC1091 -e SC2034
        exit 1
    fi

    # Search for ShellCheck Warnings in all the scripts and fail if it finds any
#    local SCDISABLED
#    SCDISABLED=$(grep -r '^# shellcheck disable' "${SCRIPTPATH}" | grep -c 'shellcheck disable')
#    if [[ ${SCDISABLED} -gt 0 ]]; then
#        error "Shellcheck disable error found"
#        grep -rn "${SCRIPTPATH}" -e '^# shellcheck disable'
#        exit 1
#    fi
}
