#!/bin/bash

SCRIPTPATH="$(cd -P "$(dirname "$SOURCE")" && pwd)"
source "${SCRIPTPATH}/scripts/common.sh"

shellcheck -V

# Check for Shellcheck errors in the code.
NoShellCheckCodeWarningsFound=$(find . -name '*.sh' -print0 | xargs -0 shellcheck -e SC1090 -e SC1091 -e SC2034)
if [[ -n $NoShellCheckCodeWarningsFound ]] ; then
    echo -e "${RED}Shellcheck warnings found$ENDCOLOR"
    find . -name '*.sh' -print0 | xargs -0 shellcheck -e SC1090 -e SC1091 -e SC2034
    exit 1
fi

# Search for ShellCheck Warnings in all the scripts and fail if it finds any
NoSCDISABLED=$(grep -r '^# shellcheck disable' "${SCRIPTPATH}" | grep -c 'shellcheck disable')
if [[ $NoSCDISABLED -gt 0 ]] ; then
    echo -e "${RED}Shellcheck disable warnings found$ENDCOLOR"
    grep -rn "${SCRIPTPATH}" -e '^# shellcheck disable'
    exit 1
fi
