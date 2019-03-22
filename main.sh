#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Usage Information
#/ Usage: sudo ds [OPTION]
#/ NOTE: ds shortcut is only available after the first run of
#/       sudo bash ~/.docker/main.sh
#/
#/ This is the main DockSTARTer script.
#/ For regular usage you can run without providing any options.
#/
#/  -b --backup <min/med/max>
#/      backup your configs (see wiki more information)
#/  -c --compose
#/      run docker-compose up with confirmation prompt
#/  -c --compose <up/down/restart/pull>
#/      run docker-compose commands without confirmation prompts
#/  -e --env
#/      update your .env file with new variables
#/  -h --help
#/      show this usage information
#/  -i --install
#/      install/update docker, docker-compose, yq and all dependencies
#/  -p --prune
#/      remove unused docker resources
#/  -t --test <test_name>
#/      run tests to check the program
#/  -u --update
#/      update DockSTARTer to the latest stable commits
#/  -u --update <branch>
#/      update DockSTARTer to the latest commits from the specified branch
##/ -v --verbose
##/     verbose
#/  -x --debug
#/      debug
#/
usage() {
    grep --color=never -Po '^#/\K.*' "${SCRIPTNAME}" || echo "Failed to display usage information."
    exit
}

# Command Line Arguments
readonly ARGS=("$@")

# Github Token for Travis CI
if [[ ${CI:-} == true ]] && [[ ${TRAVIS:-} == true ]] && [[ ${TRAVIS_SECURE_ENV_VARS:-} == true ]]; then
    readonly GH_HEADER="Authorization: token ${GH_TOKEN}"
fi

# Script Information
# https://stackoverflow.com/questions/59895/get-the-source-directory-of-a-bash-script-from-within-the-script-itself/246128#246128
get_scriptname() {
    local SOURCE
    local DIR
    SOURCE="${BASH_SOURCE[0]:-$0}" # https://stackoverflow.com/questions/35006457/choosing-between-0-and-bash-source/35006505#35006505
    while [[ -L ${SOURCE} ]]; do # resolve ${SOURCE} until the file is no longer a symlink
        DIR="$(cd -P "$(dirname "${SOURCE}")" > /dev/null 2>&1 && pwd)"
        SOURCE="$(readlink "${SOURCE}")"
        [[ ${SOURCE} != /* ]] && SOURCE="${DIR}/${SOURCE}" # if ${SOURCE} was a relative symlink, we need to resolve it relative to the path where the symlink file was located
    done
    echo "${SOURCE}"
}
readonly SCRIPTPATH="$(cd -P "$(dirname "$(get_scriptname)")" > /dev/null 2>&1 && pwd)"
readonly SCRIPTNAME="${SCRIPTPATH}/$(basename "$(get_scriptname)")"

# User/Group Information
readonly DETECTED_PUID=${SUDO_UID:-$UID}
readonly DETECTED_UNAME=$(id -un "${DETECTED_PUID}" 2> /dev/null || true)
readonly DETECTED_PGID=$(id -g "${DETECTED_PUID}" 2> /dev/null || true)
readonly DETECTED_UGROUP=$(id -gn "${DETECTED_PUID}" 2> /dev/null || true)
readonly DETECTED_HOMEDIR=$(eval echo "~${DETECTED_UNAME}" 2> /dev/null || true)

# Colors
# https://misc.flogisoft.com/bash/tip_colors_and_formatting
readonly BLU='\e[34m'
readonly GRN='\e[32m'
readonly RED='\e[31m'
readonly YLW='\e[33m'
readonly NC='\e[0m'

# Log Functions
readonly LOG_FILE="/tmp/dockstarter.log"
sudo chown "${DETECTED_PUID:-$DETECTED_UNAME}":"${DETECTED_PGID:-$DETECTED_UGROUP}" "${LOG_FILE}" > /dev/null 2>&1 || true
info() { echo -e "${NC}$(date +"%F %T") ${BLU}[INFO]${NC}       $*${NC}" | tee -a "${LOG_FILE}" >&2; }
warning() { echo -e "${NC}$(date +"%F %T") ${YLW}[WARNING]${NC}    $*${NC}" | tee -a "${LOG_FILE}" >&2; }
error() { echo -e "${NC}$(date +"%F %T") ${RED}[ERROR]${NC}      $*${NC}" | tee -a "${LOG_FILE}" >&2; }
fatal() {
    echo -e "${NC}$(date +"%F %T") ${RED}[FATAL]${NC}      $*${NC}" | tee -a "${LOG_FILE}" >&2
    exit 1
}

# Root Check
root_check() {
    if [[ ${DETECTED_PUID} == "0" ]] || [[ ${DETECTED_HOMEDIR} == "/root" ]]; then
        fatal "Running as root is not supported. Please run as a standard user with sudo."
    fi
}

# Script Runner Function
run_script() {
    local SCRIPTSNAME="${1:-}"
    shift
    if [[ -f ${SCRIPTPATH}/.scripts/${SCRIPTSNAME}.sh ]]; then
        # shellcheck source=/dev/null
        source "${SCRIPTPATH}/.scripts/${SCRIPTSNAME}.sh"
        ${SCRIPTSNAME} "$@"
    else
        fatal "${SCRIPTPATH}/.scripts/${SCRIPTSNAME}.sh not found."
    fi
}

# Test Runner Function
run_test() {
    local TESTSNAME="${1:-}"
    shift
    if [[ -f ${SCRIPTPATH}/.scripts/${TESTSNAME}.sh ]]; then
        if grep -q "test_${TESTSNAME}" "${SCRIPTPATH}/.scripts/${TESTSNAME}.sh"; then
            info "Testing ${TESTSNAME}."
            # shellcheck source=/dev/null
            source "${SCRIPTPATH}/.scripts/${TESTSNAME}.sh"
            eval "test_${TESTSNAME}" "$@" || fatal "Failed to run ${TESTSNAME}."
            info "Completed testing ${TESTSNAME}."
        else
            fatal "Test function in ${SCRIPTPATH}/.scripts/${TESTSNAME}.sh not found."
        fi
    else
        fatal "${SCRIPTPATH}/.scripts/${TESTSNAME}.sh not found."
    fi
}

# Version functions
# https://stackoverflow.com/questions/4023830/how-to-compare-two-strings-in-dot-separated-version-format-in-bash#comment92693604_4024263
vergte() { printf '%s\n%s' "${2}" "${1}" | sort -C -V; }
vergt() { ! vergte "${2}" "${1}"; }
verlte() { printf '%s\n%s' "${1}" "${2}" | sort -C -V; }
verlt() { ! verlte "${2}" "${1}"; }

# Cleanup Function
cleanup() {
    if [[ ${SCRIPTPATH} == "${DETECTED_HOMEDIR}/.docker" ]]; then
        sudo chmod +x "${SCRIPTNAME}" > /dev/null 2>&1 || fatal "ds must be executable."
    fi
    if [[ ${CI:-} == true ]] && [[ ${TRAVIS:-} == true ]] && [[ ${TRAVIS_SECURE_ENV_VARS:-} == false ]]; then
        warning "TRAVIS_SECURE_ENV_VARS is false for Pull Requests from remote branches. Please retry failed builds!"
    fi
}
trap 'cleanup' 0 1 2 3 6 14 15

# Main Function
main() {
    # Arch Check
    readonly ARCH=$(uname -m)
    if [[ ${ARCH} != "aarch64" ]] && [[ ${ARCH} != "armv7l" ]] && [[ ${ARCH} != "x86_64" ]]; then
        fatal "Unsupported architecture."
    fi
    # Terminal Check
    if [[ -n ${PS1:-} ]] || [[ ${-} == *"i"* ]]; then
        root_check
    fi
    if [[ ${CI:-} != true ]] && [[ ${TRAVIS:-} != true ]] && [[ -z ${ARGS[*]:-} ]]; then
        root_check
        if [[ ! -d ${DETECTED_HOMEDIR}/.docker/.git ]]; then
            # Anti Sudo Check
            if [[ ${EUID} == "0" ]]; then
                fatal "Using sudo during cloning on first run is not supported."
            fi
            warning "Attempting to clone DockSTARTer repo to ${DETECTED_HOMEDIR}/.docker location."
            git clone https://github.com/GhostWriters/DockSTARTer "${DETECTED_HOMEDIR}/.docker" || fatal "Failed to clone DockSTARTer repo to ${DETECTED_HOMEDIR}/.docker location."
            info "Performing first run install."
            (sudo bash "${DETECTED_HOMEDIR}/.docker/main.sh" "-i") || fatal "Failed first run install, please reboot and try again."
            exit
        elif [[ ${SCRIPTPATH} != "${DETECTED_HOMEDIR}/.docker" ]]; then
            (sudo bash "${DETECTED_HOMEDIR}/.docker/main.sh" "-u") || true
            warning "Attempting to run DockSTARTer from ${DETECTED_HOMEDIR}/.docker location."
            (sudo bash "${DETECTED_HOMEDIR}/.docker/main.sh") || true
            exit
        fi
    fi
    # Sudo Check
    if [[ ${EUID} != "0" ]]; then
        (sudo bash "${SCRIPTNAME:-}" "${ARGS[@]:-}") || true
        exit
    fi
    run_script 'symlink_ds'
    # shellcheck source=/dev/null
    source "${SCRIPTPATH}/.scripts/cmdline.sh"
    cmdline "${ARGS[@]:-}"
    readonly PROMPT="GUI"
    run_script 'menu_main'
}
main
