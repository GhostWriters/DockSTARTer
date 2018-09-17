#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

readonly SCRIPTNAME="$(basename "${0}")"
readonly SCRIPTPATH="$(readlink -m "$(dirname "${0}")")"
readonly ARGS=("$@")

# Colors
readonly BLU='\e[34m'
readonly GRN='\e[32m'
readonly RED='\e[31m'
readonly YLW='\e[33m'
readonly ENDCOLOR='\e[0m'

# Log Functions
readonly LOG_FILE="/tmp/dockstarter.log"
info()    { echo -e "$(date +"%F %T") ${BLU}[INFO]${ENDCOLOR}       $*" | tee -a "${LOG_FILE}" >&2 ; }
warning() { echo -e "$(date +"%F %T") ${YLW}[WARNING]${ENDCOLOR}    $*" | tee -a "${LOG_FILE}" >&2 ; }
error()   { echo -e "$(date +"%F %T") ${RED}[ERROR]${ENDCOLOR}      $*" | tee -a "${LOG_FILE}" >&2 ; }
fatal()   { echo -e "$(date +"%F %T") ${RED}[FATAL]${ENDCOLOR}      $*" | tee -a "${LOG_FILE}" >&2 ; exit 1 ; }

# Check Arch
readonly ARCH=$(uname -m)
if [[ ${ARCH} != "aarch64" ]] && [[ ${ARCH} != "armv7l" ]] && [[ ${ARCH} != "x86_64" ]]; then
    fatal "Unsupported architecture."
fi

# User/Group Information
readonly DETECTED_PUID=${SUDO_UID:-$UID}
readonly DETECTED_UNAME=$(id -un "${DETECTED_PUID}" 2> /dev/null || true)
readonly DETECTED_PGID=$(id -g "${DETECTED_PUID}" 2> /dev/null || true)
readonly DETECTED_UGROUP=$(id -gn "${DETECTED_PUID}" 2> /dev/null || true)
readonly DETECTED_HOMEDIR=$(eval echo "~${DETECTED_UNAME}" 2> /dev/null || true)

# Github Token for Travis CI
if [[ ${CI:-} == true ]] && [[ ${TRAVIS:-} == true ]] && [[ ${TRAVIS_SECURE_ENV_VARS} == true ]]; then
    readonly GH_HEADER="Authorization: token ${GH_TOKEN}"
fi

# Check Systemd
if [[ -L "/sbin/init" ]]; then
    readonly ISSYSTEMD=true
else
    readonly ISSYSTEMD=false
fi

# Usage Information
#/ usage: main.sh options
#/
#/ This is the main DockSTARTer script.
#/ For regular usage you can run without providing any options.
#/
#/ OPTIONS:
#/    -b --backup              create a backup of your .env file
#/    -e --env                 update your .env file with new variables
#/    -g --generate            run the docker-compose yml generator
#/    -i --install             install docker and dependencies
#/    -p --prune               remove all unused containers, networks, volumes, images and build cache
#/    -t --test                run unit test to check the program
#/    -u --update              update DockSTARTer
#/    -v --verbose             verbose
#/    -x --debug               debug
#/
#/
#/ Examples:
#/    Run installer, updater, or generator: (using their respective options)
#/    main.sh --install
#/    or
#/    main.sh -i
#/
#/    Debug or verbose can be combined with any option but should be indicated before other options:
#/    main.sh --debug --update
#/    or
#/    main.sh -du
#/
#/    Run Shellcheck test:
#/    main.sh --test validate_shellcheck
#/    or
#/    main.sh -t validate_shellcheck
#/
usage() {
    grep '^#/' "${SCRIPTPATH}/${SCRIPTNAME}" | cut -c4-
}

# Script Runner Function
run_script() {
    local SCRIPTSNAME="${1:-}"; shift
    if [[ -f ${SCRIPTPATH}/scripts/${SCRIPTSNAME}.sh ]]; then
        # shellcheck source=/dev/null
        source "${SCRIPTPATH}/scripts/${SCRIPTSNAME}.sh"
        ${SCRIPTSNAME} "$@";
    else
        fatal "${SCRIPTPATH}/scripts/${SCRIPTSNAME}.sh not found."
    fi
}

# Test Runner Function
run_test() {
    local TESTSNAME="${1:-}"; shift
    if [[ -f ${SCRIPTPATH}/tests/${TESTSNAME}.sh ]]; then
        # shellcheck source=/dev/null
        source "${SCRIPTPATH}/tests/${TESTSNAME}.sh"
        ${TESTSNAME} "$@";
    else
        fatal "${SCRIPTPATH}/tests/${TESTSNAME}.sh not found."
    fi
}

# Main Function
main() {
    run_script 'root_check'
    # shellcheck source=scripts/cmdline.sh
    source "${SCRIPTPATH}/scripts/cmdline.sh"
    cmdline "${ARGS[@]:-}"
    run_script 'menu_main'
}
main
