#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

readonly SCRIPTNAME="$(basename "${0}")"
readonly SCRIPTPATH="$(readlink -m "$(dirname "${0}")")"
readonly ARGS=("$@")

# # Colors
readonly CYAN='\e[34m'
readonly GREEN='\e[32m'
readonly RED='\e[31m'
readonly YELLOW='\e[33m'
readonly ENDCOLOR='\033[0m'

# # Check Arch
readonly ARCH=$(dpkg --print-architecture)

# # Check Systemd
if [[ -L "/sbin/init" ]]; then
    readonly ISSYSTEMD=true
else
    readonly ISSYSTEMD=false
fi

# # Github Token for Travis CI
if [[ ${CI:-} == true ]] && [[ ${TRAVIS:-} == true ]]; then
    readonly GH_HEADER="Authorization: token ${GH_TOKEN}"
fi

# # Usage Information
usage() {
    echo "Hello World"
}

# # Script Runner Function
run_script() {
    local SCRIPTSNAME="${1:-}"
    if [[ -f ${SCRIPTPATH}/scripts/${SCRIPTSNAME}.sh ]]; then
        source "${SCRIPTPATH}/scripts/${SCRIPTSNAME}.sh"
        ${SCRIPTSNAME};
    else
        exit 1
    fi
}

# # Test Runner Function
run_test() {
    local TESTSNAME="${1:-}"
    if [[ -f ${SCRIPTPATH}/tests/${TESTSNAME}.sh ]]; then
        source "${SCRIPTPATH}/tests/${TESTSNAME}.sh"
        ${TESTSNAME};
    else
        exit 1
    fi
}

# # Main Function
main() {
    run_script 'root_check'
    source "${SCRIPTPATH}/scripts/cmdline.sh"
    cmdline "${ARGS[@]}"
}
main
