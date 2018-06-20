#!/bin/bash

validate_shellcheck() {
    shellcheck -V

    # Check for Shellcheck errors in the code.
    local SCWARNINGS
    SCWARNINGS=$(find . -name '*.sh' -print0 | xargs -0 shellcheck -e SC1090 -e SC1091 -e SC2034)
    if [[ -n ${SCWARNINGS} ]] ; then
        echo -e "${RED}Shellcheck warnings found${ENDCOLOR}"
        find . -name '*.sh' -print0 | xargs -0 shellcheck -e SC1090 -e SC1091 -e SC2034
        return 1
    fi

    # Search for ShellCheck Warnings in all the scripts and fail if it finds any
    local SCDISABLED
    SCDISABLED=$(grep -r '^# shellcheck disable' "${SCRIPTPATH}" | grep -c 'shellcheck disable')
    if [[ ${SCDISABLED} -gt 0 ]] ; then
        echo -e "${RED}Shellcheck disable warnings found${ENDCOLOR}"
        grep -rn "${SCRIPTPATH}" -e '^# shellcheck disable'
        return 1
    fi
}
