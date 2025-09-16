#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a ARGS=()
ARGS=("$@")

# Github Token for CI
if [[ ${CI-} == true ]] && [[ ${TRAVIS_SECURE_ENV_VARS-} == true ]]; then
    readonly GH_HEADER="Authorization: token ${GH_TOKEN}"
    export GH_HEADER
fi

declare -rx APPLICATION_NAME='DockSTARTer'
declare -rx APPLICATION_COMMAND='ds'
declare -rx APPLICATION_REPO='https://github.com/GhostWriters/DockSTARTer'

declare DS_COMMAND
DS_COMMAND=$(command -v "${APPLICATION_COMMAND}" || true)

# User/Group Information
readonly DETECTED_PUID=${SUDO_UID:-$UID}
export DETECTED_PUID
DETECTED_UNAME=$(id -un "${DETECTED_PUID}" 2> /dev/null || true)
readonly DETECTED_UNAME
export DETECTED_UNAME
DETECTED_PGID=$(id -g "${DETECTED_PUID}" 2> /dev/null || true)
readonly DETECTED_PGID
export DETECTED_PGID
DETECTED_UGROUP=$(id -gn "${DETECTED_PUID}" 2> /dev/null || true)
readonly DETECTED_UGROUP
export DETECTED_UGROUP
DETECTED_HOMEDIR=$(eval echo "~${DETECTED_UNAME}" 2> /dev/null || true)
readonly DETECTED_HOMEDIR
export DETECTED_HOMEDIR

# System Information
ARCH=$(uname -m)
readonly ARCH
export ARCH

declare -A C DC

# Script Information
# https://stackoverflow.com/questions/59895/get-the-source-directory-of-a-bash-script-from-within-the-script-itself/246128#246128
get_scriptname() {
    # https://stackoverflow.com/questions/35006457/choosing-between-0-and-bash-source/35006505#35006505
    local SOURCE=${BASH_SOURCE[0]:-$0}
    while [[ -L ${SOURCE} ]]; do # resolve ${SOURCE} until the file is no longer a symlink
        local DIR
        DIR=$(cd -P "$(dirname "${SOURCE}")" > /dev/null 2>&1 && pwd)
        SOURCE=$(readlink "${SOURCE}")
        [[ ${SOURCE} != /* ]] && SOURCE="${DIR}/${SOURCE}" # if ${SOURCE} was a relative symlink, we need to resolve it relative to the path where the symlink file was located
    done
    echo "${SOURCE}"
}

SCRIPTPATH=$(cd -P "$(dirname "$(get_scriptname)")" > /dev/null 2>&1 && pwd)
readonly SCRIPTPATH
export SCRIPTPATH
SCRIPTNAME="${SCRIPTPATH}/$(basename "$(get_scriptname)")"
readonly SCRIPTNAME
export SCRIPTNAME

# Terminal Colors
declare -Agr B=( # Background
    [B]=$(tput setab 4 2> /dev/null || echo -e "\e[44m") # Blue
    [C]=$(tput setab 6 2> /dev/null || echo -e "\e[46m") # Cyan
    [G]=$(tput setab 2 2> /dev/null || echo -e "\e[42m") # Green
    [K]=$(tput setab 0 2> /dev/null || echo -e "\e[40m") # Black
    [M]=$(tput setab 5 2> /dev/null || echo -e "\e[45m") # Magenta
    [R]=$(tput setab 1 2> /dev/null || echo -e "\e[41m") # Red
    [W]=$(tput setab 7 2> /dev/null || echo -e "\e[47m") # White
    [Y]=$(tput setab 3 2> /dev/null || echo -e "\e[43m") # Yellow
)
declare -Agr F=( # Foreground
    [B]=$(tput setaf 4 2> /dev/null || echo -e "\e[34m") # Blue
    [C]=$(tput setaf 6 2> /dev/null || echo -e "\e[36m") # Cyan
    [G]=$(tput setaf 2 2> /dev/null || echo -e "\e[32m") # Green
    [K]=$(tput setaf 0 2> /dev/null || echo -e "\e[30m") # Black
    [M]=$(tput setaf 5 2> /dev/null || echo -e "\e[35m") # Magenta
    [R]=$(tput setaf 1 2> /dev/null || echo -e "\e[31m") # Red
    [W]=$(tput setaf 7 2> /dev/null || echo -e "\e[37m") # White
    [Y]=$(tput setaf 3 2> /dev/null || echo -e "\e[33m") # Yellow
)

BD=$(tput bold 2> /dev/null || echo -e "\e[1m") # Bold
readonly BD
export BD
UL=$(tput smul 2> /dev/null || echo -e "\e[4m") # Underline
readonly UL
export UL
NC=$(tput sgr0 2> /dev/null || echo -e "\e[0m") # No Color
readonly NC
export NC
BS=$(tput cup 1000 0 2> /dev/null || true) # Bottom of screen
readonly BS
export BS

declare -Agr C=( # Pre-defined colors
    ["Timestamp"]="${NC}"
    ["Trace"]="${F[B]}"
    ["Debug"]="${F[B]}"
    ["Info"]="${F[B]}"
    ["Notice"]="${F[G]}"
    ["Warn"]="${F[Y]}"
    ["Error"]="${F[R]}"
    ["Fatal"]="${B[R]}${F[W]}"

    ["App"]="${F[C]}"
    ["Branch"]="${F[C]}"
    ["FailingCommand"]="${F[R]}"
    ["File"]="${F[C]}${BD}"
    ["Folder"]="${F[C]}${BD}"
    ["Program"]="${F[C]}"
    ["RunningCommand"]="${F[G]}${BD}"
    ["Theme"]="${F[C]}"
    ["Update"]="${F[G]}"
    ["User"]="${F[C]}"
    ["URL"]="${F[C]}${UL}"
    ["UserCommand"]="${F[Y]}${BD}"
    ["Var"]="${F[M]}"
    ["Version"]="${F[C]}"
    ["Yes"]="${F[G]}"
    ["No"]="${F[R]}"
)

# Log Functions
MKTEMP_LOG=$(mktemp -t "${APPLICATION_NAME}.log.XXXXXXXXXX") || echo -e "Failed to create temporary log file.\nFailing command: ${C["FailingCommand"]}mktemp -t \"${APPLICATION_NAME}.log.XXXXXXXXXX\""
readonly MKTEMP_LOG
echo "DockSTARTer Log" > "${MKTEMP_LOG}"
log() {
    local TOTERM=${1-}
    local MESSAGE=${2-}
    local STRIPPED_MESSAGE
    if declare -F strip_ansi_colors > /dev/null; then
        STRIPPED_MESSAGE=$(strip_ansi_colors "${MESSAGE-}")
    fi
    if [[ -n ${TOTERM} ]]; then
        if [[ -t 2 ]]; then
            # Stderr is not being redirected, output with color
            printf '%b\n' "${MESSAGE-}" >&2
        else
            # Stderr is being redirected, output without colorr
            printf '%b\n' "${STRIPPED_MESSAGE-}" >&2
        fi
    fi
    # Output the message to the log file without color
    printf '%b\n' "${STRIPPED_MESSAGE-}" >> "${MKTEMP_LOG}"
}
timestamped_log() {
    local TOTERM=${1-}
    local LogLevelTag=${2-}
    shift 2
    LogMessage=$(printf '%b' "$@")
    # Create a notice for each argument passed to the function
    local Timestamp
    Timestamp=$(date +"%F %T")
    # Create separate notices with the same timestamp for each line in a log message
    while IFS= read -r line; do
        log "${TOTERM-}" "${NC}${C["Timestamp"]-}${Timestamp}${NC-} ${LogLevelTag}   ${line}${NC}"
    done <<< "${LogMessage}"
}
trace() { timestamped_log "${TRACE-}" "${C["Trace"]-}[TRACE ]${NC-}" "$@"; }
debug() { timestamped_log "${DEBUG-}" "${C["Debug"]-}[DEBUG ]${NC-}" "$@"; }
info() { timestamped_log "${VERBOSE-}" "${C["Info"]-}[INFO  ]${NC-}" "$@"; }
notice() { timestamped_log true "${C["Notice"]-}[NOTICE]${NC-}" "$@"; }
warn() { timestamped_log true "${C["Warn"]-}[WARN  ]${NC-}" "$@"; }
error() { timestamped_log true "${C["Error"]-}[ERROR ]${NC-}" "$@"; }
fatal() {
    timestamped_log true "${C["Fatal"]-}[FATAL ]${NC}" "$@"
    exit 1
}

[[ -f "${SCRIPTPATH}/.includes/global_variables.sh" ]] && source "${SCRIPTPATH}/.includes/global_variables.sh"
[[ -f "${SCRIPTPATH}/.includes/pm_variables.sh" ]] && source "${SCRIPTPATH}/.includes/pm_variables.sh"
[[ -f "${SCRIPTPATH}/.includes/misc_functions.sh" ]] && source "${SCRIPTPATH}/.includes/misc_functions.sh"
[[ -f "${SCRIPTPATH}/.includes/run_script.sh" ]] && source "${SCRIPTPATH}/.includes/run_script.sh"
[[ -f "${SCRIPTPATH}/.includes/dialog_functions.sh" ]] && source "${SCRIPTPATH}/.includes/dialog_functions.sh"
[[ -f "${SCRIPTPATH}/.includes/ds_functions.sh" ]] && source "${SCRIPTPATH}/.includes/ds_functions.sh"
[[ -f "${SCRIPTPATH}/.includes/test_functions.sh" ]] && source "${SCRIPTPATH}/.includes/test_functions.sh"
[[ -f "${SCRIPTPATH}/.includes/usage.sh" ]] && source "${SCRIPTPATH}/.includes/usage.sh"
[[ -f "${SCRIPTPATH}/.includes/cmdline.sh" ]] && source "${SCRIPTPATH}/.includes/cmdline.sh"
[[ -f "${SCRIPTPATH}/.includes/process_commands.sh" ]] && source "${SCRIPTPATH}/.includes/process_commands.sh"

# Check for supported CPU architecture
check_arch() {
    if [[ ${ARCH} != "aarch64" ]] && [[ ${ARCH} != "x86_64" ]]; then
        fatal "Unsupported architecture."
    fi
}

# Check if the repo exists relative to the SCRIPTPATH
check_repo() {
    if [[ -d ${SCRIPTPATH}/.git ]] && [[ -d ${SCRIPTPATH}/.includes ]] && [[ -d ${SCRIPTPATH}/.scripts ]]; then
        return
    else
        return 1
    fi
}

# Check if running as root
check_root() {
    if [[ ${DETECTED_PUID} == "0" ]] || [[ ${DETECTED_HOMEDIR} == "/root" ]]; then
        fatal "Running as '${C["User"]-}root${NC-}' is not supported.\nPlease run as a standard user."
    fi
}

# Check if running with sudo
check_sudo() {
    if [[ ${EUID} -eq 0 ]]; then
        fatal "Running with '${C["UserCommand"]-}sudo${NC-}' is not supported.\nCommands requiring '${C["UserCommand"]-}sudo${NC-}' will prompt automatically when required."
    fi
}
clone_repo() {
    warn "Attempting to clone ${APPLICATION_NAME} repo to '${C["Folder"]-}${DETECTED_HOMEDIR}/.docker${NC-}' location."
    git clone "${APPLICATION_REPO}" "${DETECTED_HOMEDIR}/.docker" ||
        fatal "Failed to clone ${APPLICATION_NAME} repo.\nFailing command: ${C["FailingCommand"]-}git clone \"${APPLICATION_REPO}\" \"${DETECTED_HOMEDIR}/.docker\""
    notice "Performing first run install."
    exec bash "${DETECTED_HOMEDIR}/.docker/main.sh" "-fvi"
}

# Cleanup Function
cleanup() {
    local -ri EXIT_CODE=$?
    trap - ERR EXIT SIGABRT SIGALRM SIGHUP SIGINT SIGQUIT SIGTERM

    if [[ ${PROMPT:-CLI} == "GUI" ]]; then
        tput reset
    fi

    sudo sh -c "cat ${MKTEMP_LOG:-/dev/null} >> ${SCRIPTPATH}/dockstarter.log" || true
    sudo rm -f "${MKTEMP_LOG-}" || true
    sudo sh -c "echo \"$(tail -1000 "${SCRIPTPATH}/dockstarter.log")\" > ${SCRIPTPATH}/dockstarter.log" || true
    sudo -E chmod +x "${SCRIPTNAME}" > /dev/null 2>&1 || true

    if [[ -n ${DIALOG_OPTIONS_FILE-} && -f ${DIALOG_OPTIONS_FILE} ]]; then
        rm -f "${DIALOG_OPTIONS_FILE}" || true
    fi

    if [[ ${CI-} == true ]] && [[ ${TRAVIS_SECURE_ENV_VARS-} == false ]]; then
        echo "TRAVIS_SECURE_ENV_VARS is false for Pull Requests from remote branches. Please retry failed builds!"
    fi

    if [[ ${EXIT_CODE} -ne 0 ]]; then
        echo "${APPLICATION_NAME} did not finish running successfully."
    fi

    exit ${EXIT_CODE}
}
trap 'cleanup' ERR EXIT SIGABRT SIGALRM SIGHUP SIGINT SIGQUIT SIGTERM

declare -gx APPLICATION_VERSION="Unknown Version"
if check_repo && declare -F ds_version > /dev/null; then
    APPLICATION_VERSION="$(ds_version)"
    if [[ -z ${APPLICATION_VERSION} ]]; then
        APPLICATION_VERSION="$(ds_branch) Unknown Version"
    fi
fi

init_check_system() {
    check_arch
    # Terminal Check
    if [[ -t 1 ]]; then
        check_root
        check_sudo
    fi
}
init_check_cloned() {
    if [[ ! -L ${DS_COMMAND} ]] && ! check_repo; then
        clone_repo
    fi
}

init_check_branch() {
    if check_repo; then
        ds_switch_branch
    fi
}

init_check_symlink() {
    if [[ -L ${DS_COMMAND} ]]; then
        local DS_SYMLINK
        DS_SYMLINK=$(readlink -f "${DS_COMMAND}")
        if [[ ${SCRIPTNAME} != "${DS_SYMLINK}" ]]; then
            if check_repo; then
                if run_script 'question_prompt' "${PROMPT:-CLI}" N "${APPLICATION_NAME} installation found at '${C["File"]-}${DS_SYMLINK}${NC-}' location. Would you like to run '${C["UserCommand"]-}${SCRIPTNAME}${NC-}' instead?"; then
                    run_script 'symlink_ds'
                    DS_COMMAND=$(command -v "${APPLICATION_COMMAND}" || true)
                    DS_SYMLINK=$(readlink -f "${DS_COMMAND}")
                fi
            fi
            warn "Attempting to run ${APPLICATION_NAME} from '${C["RunningCommand"]-}${DS_SYMLINK}${NC-}' location."
            bash "${DS_SYMLINK}" -fvu
            bash "${DS_SYMLINK}" -fvi
            exec bash "${DS_SYMLINK}" "${ARGS[@]-}"
        fi
    fi
    # Create Symlink
    run_script 'symlink_ds'
}

init_check_update() {
    local Branch
    Branch="$(ds_branch)"
    if ds_branch_exists "${Branch}"; then
        if ds_update_available; then
            warn "${APPLICATION_NAME} [${C["Version"]-}${APPLICATION_VERSION}${NC-}]"
            warn "An update to ${APPLICATION_NAME} is available."
            warn "Run '${C["UserCommand"]-}${APPLICATION_COMMAND} -u${NC-}' to update to version '${C["Version"]-}$(ds_version "${Branch}")${NC-}'."
        else
            info "${APPLICATION_NAME} [${C["Version"]-}${APPLICATION_VERSION}${NC-}]"
        fi
    else
        local MainBranch="${TARGET_BRANCH}"
        if ! ds_branch_exists "${MainBranch}"; then
            MainBranch="${SOURCE_BRANCH}"
        fi
        warn "${APPLICATION_NAME} branch '${C["Branch"]-}${Branch}${NC-}' appears to no longer exist."
        warn "${APPLICATION_NAME} is currently on version '${C["Version"]-}$(ds_version)${NC-}'."
        if ! ds_branch_exists "${MainBranch}"; then
            error "${APPLICATION_NAME} does not appear to have a '${C["Branch"]-}${TARGET_BRANCH}${NC-}' or '${C["Branch"]-}${SOURCE_BRANCH}${NC-}' branch."
        else
            warn "Run '${C["UserCommand"]-}${APPLICATION_COMMAND} -u ${MainBranch}${NC-}' to update to the latest stable release '${C["Version"]-}$(ds_version "${MainBranch}")${NC-}'."
        fi
    fi
}

init() {
    # Verify the running environment is compaitble
    init_check_system
    # Verify the repo is cloned
    init_check_cloned
    # Vefify we are on the correct brancb
    init_check_branch
    # Vefify the symlink is created
    init_check_symlink
    # Vefify that we are on the latest version
    init_check_update
}

# Main Function
main() {
    init
    cmdline "${ARGS[@]-}"
    process_commands
}

main
