#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

readonly SCRIPTNAME="$(basename "${0}")"
readonly SCRIPTPATH="$(readlink -m "$(dirname "${0}")")"
readonly ARGS=("$@")

# # Colors
readonly BLUE='\e[34m'
readonly GREEN='\e[32m'
readonly RED='\e[31m'
readonly YELLOW='\e[33m'
readonly ENDCOLOR='\e[0m'

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

# # Log Functions
readonly LOG_FILE="/tmp/dockstarter.log"
info()    { echo -e "${BLUE}[INFO]${ENDCOLOR}        $*" | tee -a "${LOG_FILE}" >&2 ; }
warning() { echo -e "${YELLOW}[WARNING]${ENDCOLOR}   $*" | tee -a "${LOG_FILE}" >&2 ; }
error()   { echo -e "${RED}[ERROR]${ENDCOLOR}        $*" | tee -a "${LOG_FILE}" >&2 ; }
fatal()   { echo -e "${RED}[FATAL]${ENDCOLOR}        $*" | tee -a "${LOG_FILE}" >&2 ; exit 1 ; }

# # Usage Information
usage() {
    info "Hello World"
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
    source "${SCRIPTPATH}/scripts/cmdline.sh"
    cmdline "${ARGS[@]}"
}
main
