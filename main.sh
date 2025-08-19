#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -rx APPLICATION_NAME='DockSTARTer'
declare -rx APPLICATION_COMMAND='ds'
declare -rx APPLICATION_REPO='https://github.com/GhostWriters/DockSTARTer'
declare -rx SOURCE_BRANCH='master'
declare -rx TARGET_BRANCH='main'

export LC_ALL=C
export PROMPT="CLI"
export MENU=false
declare -x PROCESS_APPVARS_CREATE_ALL=1
declare -x PROCESS_ENV_UPDATE=1
declare -x PROCESS_YML_MERGE=1

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
SCRIPTNAME="${SCRIPTPATH}/$(basename "$(get_scriptname)")"
readonly SCRIPTNAME

# System Information
ARCH=$(uname -m)
readonly ARCH
export ARCH

# Environment Information
declare -rx COMPOSE_FOLDER_NAME="compose"
declare -rx THEME_FOLDER_NAME=".themes"
declare -rx COMPOSE_FOLDER="${SCRIPTPATH}/${COMPOSE_FOLDER_NAME}"
declare -rx THEME_FOLDER="${SCRIPTPATH}/${THEME_FOLDER_NAME}"

declare -rx INSTANCES_FOLDER_NAME=".instances"
declare -rx TEMPLATES_FOLDER_NAME=".apps"
declare -rx APP_ENV_FOLDER_NAME="env_files"
declare -rx COMPOSE_OVERRIDE_NAME="docker-compose.override.yml"
declare -rx COMPOSE_ENV="${COMPOSE_FOLDER}/.env"
declare -rx COMPOSE_ENV_DEFAULT_FILE="${COMPOSE_FOLDER}/.env.example"
declare -rx COMPOSE_OVERRIDE="${COMPOSE_FOLDER}/${COMPOSE_OVERRIDE_NAME}"
declare -rx APP_ENV_FOLDER="${COMPOSE_FOLDER}/${APP_ENV_FOLDER_NAME}"
declare -rx TEMPLATES_FOLDER="${COMPOSE_FOLDER}/${TEMPLATES_FOLDER_NAME}"
declare -rx INSTANCES_FOLDER="${COMPOSE_FOLDER}/${INSTANCES_FOLDER_NAME}"

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

DIALOG=$(command -v dialog) || true
export DIALOG

declare -rx MENU_INI_NAME='menu.ini'
declare -rx MENU_INI_FILE="${SCRIPTPATH}/${MENU_INI_NAME}"
declare -rx THEME_FILE_NAME='theme.ini'
declare -rx DIALOGRC_NAME='.dialogrc'
declare -rx DIALOGRC="${SCRIPTPATH}/${DIALOGRC_NAME}"

declare -rix DIALOGTIMEOUT=3
declare -rix DIALOG_OK=0
declare -rix DIALOG_CANCEL=1
declare -rix DIALOG_HELP=2
declare -rix DIALOG_EXTRA=3
declare -rix DIALOG_ITEM_HELP=4
declare -rix DIALOG_ERROR=254
declare -rix DIALOG_ESC=255
readonly -a DIALOG_BUTTONS=(
    [DIALOG_OK]="OK"
    [DIALOG_CANCEL]="CANCEL"
    [DIALOG_HELP]="HELP"
    [DIALOG_EXTRA]="EXTRA"
    [DIALOG_ITEM_HELP]="ITEM_HELP"
    [DIALOG_ERROR]="ERROR"
    [DIALOG_ESC]="ESC"
)
export DIALOG_BUTTONS

declare -x BACKTITLE=''

# Log Functions
MKTEMP_LOG=$(mktemp -t "${APPLICATION_NAME}.log.XXXXXXXXXX") || echo -e "Failed to create temporary log file.\nFailing command: ${C["FailingCommand"]}mktemp -t \"${APPLICATION_NAME}.log.XXXXXXXXXX\""
readonly MKTEMP_LOG
echo "DockSTARTer Log" > "${MKTEMP_LOG}"
create_strip_ansi_colors_SEDSTRING() {
    # Create the search string to strip ANSI colors
    # String is saved after creation, so this is only done on the first call
    local -a ANSICOLORS=("${F[@]}" "${B[@]}" "${BD}" "${UL}" "${NC}" "${BS}")
    for index in "${!ANSICOLORS[@]}"; do
        # Escape characters used by sed
        ANSICOLORS[index]=$(printf '%s' "${ANSICOLORS[index]}" | sed -E 's/[]{}()[/{}\.''''$]/\\&/g')
    done
    printf '%s' "s/$(
        IFS='|'
        printf '%s' "${ANSICOLORS[*]}"
    )//g"
}
strip_ansi_colors_SEDSTRING="$(create_strip_ansi_colors_SEDSTRING)"
readonly strip_ansi_colors_SEDSTRING
strip_ansi_colors() {
    # Strip ANSI colors
    local InputString=${1-}
    sed -E "${strip_ansi_colors_SEDSTRING}" <<< "${InputString}"
}
strip_dialog_colors() {
    # Strip Dialog colors from the arguments.  Dialog colors are in the form of '\Zc', where 'c' is any character
    local InputString=${1-}
    printf '%s' "${InputString//\\Z?/}"
}
log() {
    local TOTERM=${1-}
    local MESSAGE=${2-}
    local STRIPPED_MESSAGE
    STRIPPED_MESSAGE=$(strip_ansi_colors "${MESSAGE-}")
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
        log "${TOTERM-}" "${NC}${C["Timestamp"]}${Timestamp}${NC} ${LogLevelTag}   ${line}${NC}"
    done <<< "${LogMessage}"
}
trace() { timestamped_log "${TRACE-}" "${C["Trace"]}[TRACE ]${NC}" "$@"; }
debug() { timestamped_log "${DEBUG-}" "${C["Debug"]}[DEBUG ]${NC}" "$@"; }
info() { timestamped_log "${VERBOSE-}" "${C["Info"]}[INFO  ]${NC}" "$@"; }
notice() { timestamped_log true "${C["Notice"]}[NOTICE]${NC}" "$@"; }
warn() { timestamped_log true "${C["Warn"]}[WARN  ]${NC}" "$@"; }
error() { timestamped_log true "${C["Error"]}[ERROR ]${NC}" "$@"; }
fatal() {
    timestamped_log true "${C["Fatal"]}[FATAL ]${NC}" "$@"
    exit 1
}

# Check for supported CPU architecture
check_arch() {
    if [[ ${ARCH} != "aarch64" ]] && [[ ${ARCH} != "x86_64" ]]; then
        fatal "Unsupported architecture."
    fi
}

# Check if the repo exists relative to the SCRIPTPATH
check_repo() {
    if [[ -d ${SCRIPTPATH}/.git ]] && [[ -d ${SCRIPTPATH}/.scripts ]]; then
        return
    else
        return 1
    fi
}

# Check if running as root
check_root() {
    if [[ ${DETECTED_PUID} == "0" ]] || [[ ${DETECTED_HOMEDIR} == "/root" ]]; then
        fatal "Running as '${C["User"]}root${NC}' is not supported. Please run as a standard user."
    fi
}

# Check if running with sudo
check_sudo() {
    if [[ ${EUID} -eq 0 ]]; then
        fatal "Running with '${C["UserCommand"]}sudo${NC}' is not supported. Commands requiring '${C["UserCommand"]}sudo${NC}' will prompt automatically when required."
    fi
}

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

# Take whitespace and newline delimited words and output a single line highlited list for dialog
highlighted_list() {
    local List
    List=$(xargs <<< "$*")
    if [[ -n ${List-} ]]; then
        echo "${DC["Subtitle"]}${List// /${DC[NC]} ${DC["Subtitle"]}}${DC[NC]}"
    fi
}

_dialog_backtitle_() {
    local LeftBackTitle RightBackTitle
    local CleanLeftBackTitle CleanRightBackTitle

    CleanLeftBackTitle="${APPLICATION_NAME}"
    LeftBackTitle="${DC[ApplicationName]}${APPLICATION_NAME}${DC[NC]}"

    CleanRightBackTitle=''
    RightBackTitle=''
    if ds_update_available; then
        CleanRightBackTitle="(Update Available)"
        RightBackTitle="${DC[ApplicationUpdateBrackets]}(${DC[ApplicationUpdate]}Update Available${DC[ApplicationUpdateBrackets]})${DC[NC]}"
    fi
    if [[ ${APPLICATION_VERSION-} ]]; then
        if [[ -n ${CleanRightBackTitle-} ]]; then
            CleanRightBackTitle+=" "
            RightBackTitle+="${DC[ApplicationVersionSpace]} "
        fi
        local CurrentVersion
        CurrentVersion="$(ds_version)"
        if [[ -z ${CurrentVersion} ]]; then
            CurrentVersion="$(ds_branch) Unknown Version"
        fi
        CleanRightBackTitle+="[${CurrentVersion}]"
        RightBackTitle+="${DC[ApplicationVersionBrackets]}[${DC[ApplicationVersion]}${CurrentVersion}${DC[ApplicationVersionBrackets]}]${DC[NC]}"
    fi

    local -i IndentLength
    IndentLength=$((COLUMNS - ${#CleanLeftBackTitle} - ${#CleanRightBackTitle} - 2))
    local Indent
    Indent="$(printf %${IndentLength}s '')"
    BACKTITLE="${LeftBackTitle}${Indent}${RightBackTitle}"
}

_dialog_() {
    _dialog_backtitle_
    ${DIALOG} --file "${DIALOG_OPTIONS_FILE}" --backtitle "${BACKTITLE}" "$@"
}

# Check to see if we should use a dialog box
use_dialog_box() {
    [[ ${PROMPT:-CLI} == GUI && -t 1 && -t 2 ]]
}

# Pipe to Dialog Box Function
dialog_pipe() {
    local Title=${1:-}
    local SubTitle=${2:-}
    local TimeOut=${3:-0}
    _dialog_ \
        --title "${DC["Title"]}${Title}" \
        --timeout "${TimeOut}" \
        --programbox "${DC["Subtitle"]}${SubTitle}" \
        "$((LINES - DC["WindowRowsAdjust"]))" "$((COLUMNS - DC["WindowColsAdjust"]))" || true
    echo -n "${BS}"
}
# Script Dialog Runner Function
run_script_dialog() {
    local Title=${1:-}
    local SubTitle=${2:-}
    local TimeOut=${3:-0}
    local SCRIPTSNAME=${4-}
    shift 4
    if use_dialog_box; then
        # Using the GUI, pipe output to a dialog box
        SubTitle="$(strip_ansi_colors "${SubTitle}")"
        coproc {
            dialog_pipe "${Title}" "${SubTitle}" "${TimeOut}"
        }
        local -i DialogBox_PID=${COPROC_PID}
        local -i DialogBox_FD="${COPROC[1]}"
        local -i result=0
        run_script "${SCRIPTSNAME}" "$@" >&${DialogBox_FD} 2>&1 || result=$?
        exec {DialogBox_FD}<&-
        wait ${DialogBox_PID}
        return ${result}
    else
        run_script "${SCRIPTSNAME}" "$@"
        return
    fi
}

# Command Dialog Runner Function
run_command_dialog() {
    local Title=${1:-}
    local SubTitle=${2:-}
    local TimeOut=${3:-0}
    local CommandName=${4-}
    shift 4
    if [[ -n ${CommandName-} ]]; then
        if use_dialog_box; then
            # Using the GUI, pipe output to a dialog box
            SubTitle="$(strip_ansi_colors "${SubTitle}")"
            "${CommandName}" "$@" |& dialog_pipe "${Title}" "${SubTitle}" "${TimeOut}"
            return "${PIPESTATUS[0]}"
        else
            "${CommandName}" "$@"
            return
        fi
    fi
}

dialog_info() {
    local Title=${1:-}
    local Message=${2:-}
    Title="$(strip_ansi_colors "${Title}")"
    Message="$(strip_ansi_colors "${Message}")"
    _dialog_ \
        --title "${Title}" \
        --infobox "${Message}" \
        "$((LINES - DC["WindowRowsAdjust"]))" "$((COLUMNS - DC["WindowColsAdjust"]))"
    echo -n "${BS}"
}
dialog_message() {
    local Title=${1:-}
    local Message=${2:-}
    local TimeOut=${3:-0}
    Title="$(strip_ansi_colors "${Title}")"
    Message="$(strip_ansi_colors "${Message}")"
    _dialog_ \
        --title "${Title}" \
        --timeout "${TimeOut}" \
        --msgbox "${Message}" \
        "$((LINES - DC["WindowRowsAdjust"]))" "$((COLUMNS - DC["WindowColsAdjust"]))"
    echo -n "${BS}"
}
dialog_error() {
    local Title=${1:-}
    local Message=${2:-}
    local TimeOut=${3:-0}
    dialog_message "${DC["TitleError"]}${Title}" "${Message}" "${TimeOut}"
}
dialog_warning() {
    local Title=${1:-}
    local Message=${2:-}
    local TimeOut=${3:-0}
    dialog_message "${DC["TitleWarning"]}${Title}" "${Message}" "${TimeOut}"
}
dialog_success() {
    local Title=${1:-}
    local Message=${2:-}
    local TimeOut=${3:-0}
    dialog_message "${DC["TitleSuccess"]}${Title}" "${Message}" "${TimeOut}"
}

ds_branch() {
    pushd "${SCRIPTPATH}" &> /dev/null || fatal "Failed to change directory.\nFailing command: ${C["FailingCommand"]}pushd \"${SCRIPTPATH}\""
    git fetch --quiet &> /dev/null || true
    git symbolic-ref --short HEAD 2> /dev/null || true
    popd &> /dev/null
}

ds_branch_exists() {
    local CurrentBranch
    CurrentBranch="$(ds_branch)"
    local CheckBranch
    CheckBranch=${1:-"${CurrentBranch}"}

    pushd "${SCRIPTPATH}" &> /dev/null || fatal "Failed to change directory.\nFailing command: ${C["FailingCommand"]}pushd \"${SCRIPTPATH}\""
    local -i result=0
    git ls-remote --exit-code --heads origin "${CheckBranch}" &> /dev/null || result=$?
    popd &> /dev/null
    return ${result}
}

ds_version() {
    local CheckBranch
    CheckBranch=${1-}
    local commitish Branch
    if [[ -n ${CheckBranch-} ]]; then
        commitish="origin/${CheckBranch}"
        Branch="${CheckBranch}"
    else
        commitish='HEAD'
        Branch="$(ds_branch)"
    fi

    pushd "${SCRIPTPATH}" &> /dev/null || fatal "Failed to change directory.\nFailing command: ${C["FailingCommand"]}pushd \"${SCRIPTPATH}\""
    if [[ -z ${CheckBranch-} ]] || ds_branch_exists "${Branch}"; then
        # Get the current tag. If no tag, use the commit instead.
        local VersionString
        VersionString="$(git describe --tags --exact-match "${commitish}" 2> /dev/null || true)"
        if [[ -z ${VersionString-} ]]; then
            VersionString="commit $(git rev-parse --short "${commitish}" 2> /dev/null || true)"
        fi
        VersionString="${Branch} ${VersionString}"
    else
        VersionString=''
    fi
    echo "${VersionString}"
    popd &> /dev/null
}
ds_update_available() {
    pushd "${SCRIPTPATH}" &> /dev/null || fatal "Failed to change directory.\nFailing command: ${C["FailingCommand"]}pushd \"${SCRIPTPATH}\""
    git fetch --quiet &> /dev/null
    local -i result=0
    # shellcheck disable=SC2319 # This $? refers to a condition, not a command. Assign to a variable to avoid it being overwritten.
    [[ $(git rev-parse HEAD 2> /dev/null) != $(git rev-parse '@{u}' 2> /dev/null) ]] || result=$?
    popd &> /dev/null
    return ${result}
}

switch_branch() {
    local CurrentBranch
    CurrentBranch="$(ds_branch)"
    if [[ ${CurrentBranch} == "${SOURCE_BRANCH}" ]] && ds_branch_exists "${TARGET_BRANCH}"; then
        FORCE=true
        export FORCE
        PROMPT="CLI"
        notice "Automatically switching from ${APPLICATION_NAME} branch '${C["Branch"]}${SOURCE_BRANCH}${NC}' to '${C["Branch"]}${TARGET_BRANCH}${NC}'."
        run_script 'update_self' "${TARGET_BRANCH}" bash "${SCRIPTNAME}" "$@"
        exit
    fi
}

declare -x APPLICATION_VERSION
if check_repo; then
    APPLICATION_VERSION="$(ds_version)"
    if [[ -z ${APPLICATION_VERSION} ]]; then
        APPLICATION_VERSION="$(ds_branch) Unknown Version"
    fi
else
    APPLICATION_VERSION="Unknown Version"
fi
readonly APPLICATION_VERSION

usage() {
    local APPLICATION_HEADING="${APPLICATION_NAME}"
    if [[ ${APPLICATION_VERSION-} ]]; then
        APPLICATION_HEADING+=" [${C["Version"]}${APPLICATION_VERSION}${NC}]"
    fi
    if ds_update_available; then
        APPLICATION_HEADING+=" (${C["Update"]}Update Available${NC})"
    fi
    cat << EOF
Usage: ${APPLICATION_COMMAND} [<OPTION> ...]
NOTE: ${APPLICATION_COMMAND} shortcut is only available after the first run of
    bash main.sh

${APPLICATION_HEADING}
This is the main ${APPLICATION_NAME} script.
For regular usage you can run without providing any options.

Any command that takes a variable name, the variable name can also be in the
form of 'app:var' to refer to the variable '<var>' in '.env.app.<app>'.  Some commands
that take app names can use the form 'app:' to refer to the same file.

-a --add <app> [<app> ...]
    Add the default '.env' variables for the app(s) specified
-c --compose <pull/up/down/stop/restart/update> [<app> ...]
    Run docker compose commands. If no command is given, does an update.
    Update is the same as a 'pull' followed by an 'up'
-c --compose <generate/merge>
    Generates the docker-compose.yml file
-e --env
    Update your '.env' file with new variables
--env-appvars <app> [<app> ...]
    List all variable names for the app(s) specified
--env-appvars-lines <app> [<app> ...]
    List all variables and values for the app(s) specified
--env-get <var> [<var> ...]
--env-get=<var>
    Get the value of a <var>iable in '.env' (variable name is forced to UPPER CASE)
--env-get-line <var> [<var> ...]
--env-get-line=<var>
    Get the line of a <var>iable in '.env' (variable name is forced to UPPER CASE)
--env-get-literal <var> [<var> ...]
--env-get-literal=<var>
    Get the literal value (including quotes) of a <var>iable in '.env' (variable name is forced to UPPER CASE)
--env-get-lower <var> [<var> ...]
--env-get-lower=<var>
    Get the value of a <var>iable in .env
--env-get-lower-line <var> [<var> ...]
--env-get-lower-line=<var>
    Get the line of a <var>iable in .env
--env-get-lower-literal <var> [<var> ...]
--env-get-lower-literal=<var>
    Get the literal value (including quotes) of a <var>iable in .env
--env-set <var>=<val>
--env-set=<var>,<val>
    Set the <val>ue of a <var>iable in '.env' (variable name is forced to UPPER CASE)
--env-set-lower <var>=<val>
--env-set-lower=<var>,<val>
    Set the <val>ue of a <var>iable in .env
-f --force
    Force certain install/upgrade actions to run even if they would not be needed
-g --gui
    Use dialog boxes
-l --list
    List all apps
--list-added
    List added apps
--list-builtin
    List builtin apps
--list-deprecated
    List deprecated apps
--list-enabled
    List enabled apps
--list-disabled
    List disabled apps
--list-nondeprecated
    List non-deprecated apps
--list-referenced
    List referenced apps (whether they are "built in" or not)
    An app is considered "referenced" if there is a variable matching the app's name in the
    global '.env' file, or there are any variables in the file '.env.app<appname>'.
-h --help
    Show this usage information
-i --install
    Install/update all dependencies
-p --prune
    Remove unused docker resources
-r --remove
    Prompt to remove '.env' variables for all disabled apps
-r --remove <appname>
    Prompt to remove the '.env' variables for the app specified
-s --status <appname>
    Returns the enabled/disabled status for the app specified
-S --select
    Bring up the application selection menu
--status-disable <appname>
    Disable the app specified
--status-enable <appname>
    Enable the app specified
-t --test <test_name>
    Run tests to check the program
-T --theme <themename>
    Applies the specified theme to the GUI
--theme-list
    Lists the available themes
--theme-table
    Lists the available themes in a table format
--theme-lines
--theme-no-lines
    Turn the line drawing characters on or off in the GUI
--theme-borders
--theme-no-borders
    Turn the borders on and off inthe  GUI
--theme-shadow
--theme-no-shadow
    Turn the shadow on or off in the GUI
--theme-scrollbar
--theme-no-scrollbar
    Turn the scrollbar on or off in the GUI
-u --update
    Update ${APPLICATION_NAME} to the latest stable commits
-u --update <branch>
    Update ${APPLICATION_NAME} to the latest commits from the specified branch
-v --verbose
    Verbose
-V --version
    Display version information
-x --debug
    Debug
EOF
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

# Command Line Arguments
readonly ARGS=("$@")
cmdline() {
    while getopts ":-:a:c:efghilpr:s:St:T:u:vV:x" OPTION; do
        # support long options: https://stackoverflow.com/a/28466267/519360
        if [ "$OPTION" = "-" ]; then # long option: reformulate OPTION and OPTARG
            OPTION="${OPTARG}"       # extract long option name
            OPTARG=''
            if [[ -n ${!OPTIND-} ]]; then
                OPTARG="${!OPTIND}"
                OPTIND=$((OPTIND + 1))
            fi
        fi
        case ${OPTION} in
            a | add)
                if [[ -n ${OPTARG-} ]]; then
                    local MULTIOPT
                    MULTIOPT=("$OPTARG")
                    until [[ -z ${!OPTIND-} || ${!OPTIND} =~ ^-.* ]]; do
                        MULTIOPT+=("${!OPTIND}")
                        OPTIND=$((OPTIND + 1))
                    done
                    ADD=$(printf "%s " "${MULTIOPT[@]}" | xargs)
                    readonly ADD
                else
                    error "'${C["UserCommand"]}${OPTION}${NC}' requires an option."
                    exit 1
                fi
                ;;
            c | compose)
                if [[ -n ${OPTARG-} ]]; then
                    case ${OPTARG} in
                        generate | merge) ;&
                        down | pull | stop | restart | update | up) ;&
                        "down "* | "pull "* | "stop "* | "restart "* | "update "* | "up "*)
                            local MULTIOPT
                            MULTIOPT=("$OPTARG")
                            until [[ -z ${!OPTIND-} || ${!OPTIND} =~ ^-.* ]]; do
                                MULTIOPT+=("${!OPTIND}")
                                OPTIND=$((OPTIND + 1))
                            done
                            COMPOSE=$(printf "%s " "${MULTIOPT[@]}" | xargs)
                            readonly COMPOSE
                            ;;
                        *)
                            error "Invalid compose option '${C["UserCommand"]}${OPTARG}${NC}'."
                            exit 1
                            ;;
                    esac
                else
                    readonly COMPOSE=update
                fi
                ;;
            e | env)
                readonly ENVMETHOD='env'
                ;;
            env-appvars | env-appvars-lines)
                readonly ENVMETHOD=${OPTION}
                local MULTIOPT
                MULTIOPT=("$OPTARG")
                until [[ -z ${!OPTIND-} || ${!OPTIND} =~ ^-.* ]]; do
                    MULTIOPT+=("${!OPTIND}")
                    OPTIND=$((OPTIND + 1))
                done
                ENVAPP=$(printf "%s " "${MULTIOPT[@]}" | xargs)
                readonly ENVAPP
                ;;
            env-get=* | env-get-lower=* | env-get-line=* | env-get-lower-line=* | env-get-literal=* | env-get-lower-literal=*)
                readonly ENVMETHOD=${OPTION%%=*}
                readonly ENVARG=${OPTION#*=}
                if [[ ${ENVMETHOD-} != "${ENVARG-}" ]]; then
                    readonly ENVVAR=${ENVARG}
                fi
                ;;
            env-set=* | env-set-lower=*)
                readonly ENVMETHOD=${OPTION%%=*}
                readonly ENVARG=${OPTION#*=}
                if [[ ${ENVMETHOD-} != "${ENVARG-}" ]]; then
                    readonly ENVVAR=${ENVARG%%,*}
                    readonly ENVVAL=${ENVARG#*,}
                fi
                ;;
            env-get | env-get-lower | env-get-line | env-get-lower-line | env-get-literal | env-get-lower-literal)
                readonly ENVMETHOD=${OPTION}
                if [[ -z ${ENVVAR-} ]]; then
                    local MULTIOPT
                    MULTIOPT=("$OPTARG")
                    until [[ -z ${!OPTIND-} || ${!OPTIND} =~ ^-.* ]]; do
                        MULTIOPT+=("${!OPTIND}")
                        OPTIND=$((OPTIND + 1))
                    done
                    ENVVAR=$(printf "%s " "${MULTIOPT[@]}" | xargs)
                    readonly ENVVAR
                fi
                ;;
            env-set | env-set-lower)
                readonly ENVMETHOD=${OPTION}
                if [[ -z ${ENVVAR-} ]]; then
                    readonly ENVARG=${OPTARG}
                    readonly ENVVAR=${ENVARG%%=*}
                    readonly ENVVAL=${ENVARG#*=}
                fi
                ;;
            f | force)
                readonly FORCE=true
                export FORCE
                ;;
            g | gui)
                if [[ -n ${DIALOG-} ]]; then
                    PROMPT="GUI"
                else
                    warn "The '${C["UserCommand"]}--gui${NC}' option requires the '${C["Program"]}dialog$}NC}' command to be installed."
                    warn "'${C["Program"]}dialog${NC}' command not found. Run '${C["UserCommand"]}${APPLICATION_COMMAND} -fiv${NC}' to install all dependencies."
                    warn "Coninuing without '${C["UserCommand"]}--gui${NC}' option."
                fi
                ;;
            h | help)
                usage
                exit
                ;;
            i | install)
                readonly INSTALL=true
                ;;
            l | list)
                readonly LISTMETHOD='list'
                readonly LIST=true
                ;;
            list-*)
                readonly LISTMETHOD=${OPTION}
                ;;
            p | prune)
                readonly PRUNE=true
                ;;
            r | remove)
                if [[ -n ${OPTARG-} ]]; then
                    local MULTIOPT
                    MULTIOPT=("$OPTARG")
                    until [[ -z ${!OPTIND-} || ${!OPTIND} =~ ^-.* ]]; do
                        MULTIOPT+=("${!OPTIND}")
                        OPTIND=$((OPTIND + 1))
                    done
                    REMOVE=$(printf "%s " "${MULTIOPT[@]}" | xargs)
                    readonly REMOVE
                else
                    error "'${C["UserCommand"]}${OPTION}${NC}' requires an option."
                    exit 1
                fi
                ;;
            status-*)
                if [[ -n ${OPTARG-} ]]; then
                    readonly STATUSMETHOD=${OPTION}
                    local MULTIOPT
                    MULTIOPT=("$OPTARG")
                    until [[ -z ${!OPTIND-} || ${!OPTIND} =~ ^-.* ]]; do
                        MULTIOPT+=("${!OPTIND}")
                        OPTIND=$((OPTIND + 1))
                    done
                    STATUS=$(printf "%s " "${MULTIOPT[@]}" | xargs)
                    readonly STATUS
                else
                    error "'${C["UserCommand"]}${OPTION}${NC}' requires an option."
                    exit 1
                fi
                ;;
            s | status)
                if [[ -n ${OPTARG-} ]]; then
                    readonly STATUSMETHOD='status'
                    local MULTIOPT
                    MULTIOPT=("$OPTARG")
                    until [[ -z ${!OPTIND-} || ${!OPTIND} =~ ^-.* ]]; do
                        MULTIOPT+=("${!OPTIND}")
                        OPTIND=$((OPTIND + 1))
                    done
                    STATUS=$(printf "%s " "${MULTIOPT[@]}" | xargs)
                    readonly STATUS
                else
                    error "'${C["UserCommand"]}${OPTION}${NC}' requires an option."
                    exit 1
                fi
                ;;
            S | select)
                readonly SELECT=1
                ;;
            t | test)
                if [[ -n ${OPTARG-} ]]; then
                    readonly TEST=${OPTARG}
                else
                    error "'${C["UserCommand"]}${OPTION}${NC}' requires an option."
                    exit 1
                fi
                ;;
            T | theme)
                readonly THEMEMETHOD='theme'
                if [[ -n ${OPTARG-} ]]; then
                    readonly THEME="${OPTARG}"
                    OPTIND=$((OPTIND + 1))
                fi
                ;;
            theme-*)
                readonly THEMEMETHOD=${OPTION}
                ;;
            u | update)
                UPDATE=true
                if [[ -n ${OPTARG-} ]]; then
                    UPDATE="${OPTARG}"
                fi
                readonly UPDATE
                ;;
            v | verbose)
                readonly VERBOSE=1
                ;;
            V | version)
                VERSION=''
                if [[ -n ${OPTARG-} && ${OPTARG:0:1} != '-' ]]; then
                    VERSION="${OPTARG}"
                fi
                readonly VERSION
                ;;
            x | debug)
                readonly DEBUG=1
                set -x
                ;;
            :)
                case ${OPTARG} in
                    c)
                        readonly COMPOSE=update
                        ;;
                    r)
                        readonly REMOVE=true
                        ;;
                    T)
                        readonly THEMEMETHOD='theme'
                        ;;
                    u)
                        readonly UPDATE=true
                        ;;
                    V)
                        readonly VERSION=''
                        ;;
                    *)
                        error "'${C["UserCommand"]}${OPTARG}${NC}' requires an option."
                        exit 1
                        ;;
                esac
                ;;
            *)
                usage
                exit
                ;;
        esac
    done
    return
}

if check_repo; then
    switch_branch "${ARGS[@]-}"
fi
cmdline "${ARGS[@]-}"
if [[ -n ${DEBUG-} ]] && [[ -n ${VERBOSE-} ]]; then
    readonly TRACE=1
fi

# Test Runner Function
run_test() {
    local SCRIPTSNAME=${1-}
    shift
    local TESTSNAME="test_${SCRIPTSNAME}"
    if [[ -f ${SCRIPTPATH}/.scripts/${SCRIPTSNAME}.sh ]]; then
        if grep -q -P "${TESTSNAME}" "${SCRIPTPATH}/.scripts/${SCRIPTSNAME}.sh"; then
            notice "Testing '${C["RunningCommand"]}${SCRIPTSNAME}${NC}'."
            # shellcheck source=/dev/null
            source "${SCRIPTPATH}/.scripts/${SCRIPTSNAME}.sh"
            "${TESTSNAME}" "$@" || fatal "Failed to run '${C["FailingCommand"]}${TESTSNAME}${NC}'."
            notice "Completed testing '${C["RunningCommand"]}${TESTSNAME}${NC}'."
        else
            fatal "Test function in '${C["File"]}${SCRIPTPATH}/.scripts/${SCRIPTSNAME}.sh${NC}' not found."
        fi
    else
        fatal "${SCRIPTPATH}/.scripts/${SCRIPTSNAME}.sh not found."
    fi
}

# Version Functions
# https://stackoverflow.com/questions/4023830/how-to-compare-two-strings-in-dot-separated-version-format-in-bash#comment92693604_4024263
vergte() { printf '%s\n%s' "${2}" "${1}" | sort -C -V; }
vergt() { ! vergte "${2}" "${1}"; }
verlte() { printf '%s\n%s' "${1}" "${2}" | sort -C -V; }
verlt() { ! verlte "${2}" "${1}"; }

# Github Token for CI
if [[ ${CI-} == true ]] && [[ ${TRAVIS_SECURE_ENV_VARS-} == true ]]; then
    readonly GH_HEADER="Authorization: token ${GH_TOKEN}"
    export GH_HEADER
fi

# Main Function
main() {
    check_arch
    # Terminal Check
    if [[ -t 1 ]]; then
        check_root
        check_sudo
    fi
    # Repo Check
    local DS_COMMAND
    DS_COMMAND=$(command -v "${APPLICATION_COMMAND}" || true)
    if [[ -L ${DS_COMMAND} ]]; then
        local DS_SYMLINK
        DS_SYMLINK=$(readlink -f "${DS_COMMAND}")
        if [[ ${SCRIPTNAME} != "${DS_SYMLINK}" ]]; then
            if check_repo; then
                if run_script 'question_prompt' "${PROMPT:-CLI}" N "${APPLICATION_NAME} installation found at '${C["File"]}${DS_SYMLINK}${NC}' location. Would you like to run '${C["UserCommand"]}${SCRIPTNAME}${NC}' instead?"; then
                    run_script 'symlink_ds'
                    DS_COMMAND=$(command -v "${APPLICATION_COMMAND}" || true)
                    DS_SYMLINK=$(readlink -f "${DS_COMMAND}")
                fi
            fi
            warn "Attempting to run ${APPLICATION_NAME} from '${C["RunningCommand"]}${DS_SYMLINK}${NC}' location."
            bash "${DS_SYMLINK}" -fvu
            bash "${DS_SYMLINK}" -fvi
            exec bash "${DS_SYMLINK}" "${ARGS[@]-}"
        fi
    else
        if ! check_repo; then
            warn "Attempting to clone ${APPLICATION_NAME} repo to '${C["Folder"]}${DETECTED_HOMEDIR}/.docker${NC}' location."
            git clone "${APPLICATION_REPO}" "${DETECTED_HOMEDIR}/.docker" || fatal "Failed to clone ${APPLICATION_NAME} repo.\nFailing command: ${C["FailingCommand"]}git clone \"${APPLICATION_REPO}\" \"${DETECTED_HOMEDIR}/.docker\""
            notice "Performing first run install."
            exec bash "${DETECTED_HOMEDIR}/.docker/main.sh" "-fvi"
        fi
    fi
    # Create Symlink
    run_script 'symlink_ds'
    local Branch
    Branch="$(ds_branch)"
    if ds_branch_exists "${Branch}"; then
        if ds_update_available; then
            warn "${APPLICATION_NAME} [${C["Version"]}${APPLICATION_VERSION}${NC}]"
            warn "An update to ${APPLICATION_NAME} is available."
            warn "Run '${C["UserCommand"]}${APPLICATION_COMMAND} -u${NC}' to update to version '${C["Version"]}$(ds_version "${Branch}")${NC}'."
        else
            info "${APPLICATION_NAME} [${C["Version"]}${APPLICATION_VERSION}${NC}]"
        fi
    else
        local MainBranch="${TARGET_BRANCH}"
        if ! ds_branch_exists "${MainBranch}"; then
            MainBranch="${SOURCE_BRANCH}"
        fi
        warn "${APPLICATION_NAME} branch '${C["Branch"]}${Branch}${NC}' appears to no longer exist."
        warn "${APPLICATION_NAME} is currently on version '${C["Version"]}$(ds_version)${NC}'."
        if ! ds_branch_exists "${MainBranch}"; then
            error "${APPLICATION_NAME} does not appear to have a '${C["Branch"]}${TARGET_BRANCH}${NC}' or '${C["Branch"]}${SOURCE_BRANCH}${NC}' branch."
        else
            warn "Run '${C["UserCommand"]}${APPLICATION_COMMAND} -u ${MainBranch}${NC}' to update to the latest stable release '${C["Version"]}$(ds_version "${MainBranch}")${NC}'."
        fi
    fi
    # Apply the GUI theme
    run_script 'apply_theme'
    # Check if we're running a test
    if [[ -n ${TEST-} ]]; then
        run_test "${TEST}"
        exit
    fi

    # Execute CLI Argument Functions
    if [[ -n ${INSTALL-} ]]; then
        run_script 'run_install'
        exit
    fi
    if [[ -n ${UPDATE-} ]]; then
        if [[ ${UPDATE} == true ]]; then
            run_script 'update_self'
        else
            run_script 'update_self' "${UPDATE}"
        fi
        exit
    fi
    if [[ -v VERSION ]]; then
        local VersionString
        VersionString="$(ds_version "${VERSION}")"
        if [[ -n ${VersionString} ]]; then
            echo "${APPLICATION_NAME} [${VersionString}]"
        else
            local Branch
            Branch="${VERSION:-$(ds_branch)}"
            error "${APPLICATION_NAME} branch '${C["Branch"]}${Branch}${NC}' does not exist."
        fi
        exit
    fi
    if [[ -n ${PRUNE-} ]]; then
        run_script 'docker_prune'
        exit
    fi
    if [[ -n ${THEMEMETHOD-} ]]; then
        case "${THEMEMETHOD}" in
            theme)
                local NoticeText
                local CommandLine
                if [[ -n ${THEME-} ]]; then
                    NoticeText="Applying ${APPLICATION_NAME} theme '${C["Theme"]}${THEME}${NC}'"
                    CommandLine="${APPLICATION_COMMAND} --theme \"${THEME}\""
                else
                    NoticeText="Applying ${APPLICATION_NAME} theme '${C["Theme"]}$(run_script 'theme_name')${NC}'"
                    CommandLine="${APPLICATION_COMMAND} --theme"
                fi
                notice "${NoticeText}"
                if use_dialog_box; then
                    run_script 'apply_theme' "${THEME-}" && run_script 'menu_dialog_example' "" "${CommandLine}"
                else
                    run_script 'apply_theme' "${THEME-}"
                fi
                ;;
            theme-list)
                run_script_dialog "List Themes" "" "" \
                    'theme_list'
                ;;
            theme-table)
                run_script_dialog "List Themes" "" "" \
                    'theme_table'
                ;;
            theme-shadow)
                notice "Turning on GUI shadows."
                run_script 'config_set' Shadow yes "${MENU_INI_FILE}"
                if use_dialog_box; then
                    run_script 'menu_dialog_example' "Turned on shadows" "${APPLICATION_COMMAND} --theme-shadow"
                fi
                ;;
            theme-no-shadow)
                run_script 'config_set' Shadow no "${MENU_INI_FILE}"
                notice "Turning off GUI shadows."
                if use_dialog_box; then
                    run_script 'menu_dialog_example' "Turned off shadows" "${APPLICATION_COMMAND} --theme-no-shadow"
                fi
                ;;
            theme-scrollbar)
                run_script 'config_set' Scrollbar yes "${MENU_INI_FILE}"
                notice "Turning on GUI scrollbars."
                if use_dialog_box; then
                    run_script 'menu_dialog_example' "Turned on scrollbars" "${APPLICATION_COMMAND} --theme-scrollbar"
                fi
                ;;
            theme-no-scrollbar)
                run_script 'config_set' Scrollbar no "${MENU_INI_FILE}"
                notice "Turning off GUI scrollbars."
                if use_dialog_box; then
                    run_script 'menu_dialog_example' "Turned off scrollbars" "${APPLICATION_COMMAND} --theme-no-scrollbar"
                fi
                ;;
            theme-lines)
                run_script 'config_set' LineCharacters yes "${MENU_INI_FILE}"
                notice "Turning on GUI line drawing characters."
                if use_dialog_box; then
                    run_script 'menu_dialog_example' "Turned on line drawing" "${APPLICATION_COMMAND} --theme-lines"
                fi
                ;;
            theme-no-lines)
                notice "Turning off GUI line drawing characters."
                run_script 'config_set' LineCharacters no "${MENU_INI_FILE}"
                if use_dialog_box; then
                    run_script 'menu_dialog_example' "Turned off line drawing" "${APPLICATION_COMMAND} --theme-no-lines"
                fi
                ;;
            theme-borders)
                run_script 'config_set' Borders yes "${MENU_INI_FILE}"
                notice "Turning on GUI borders."
                if use_dialog_box; then
                    run_script 'menu_dialog_example' "Turned on borders" "${APPLICATION_COMMAND} --theme-borders"
                fi
                ;;
            theme-no-borders)
                notice "Turning off GUI borders."
                run_script 'config_set' Borders no "${MENU_INI_FILE}"
                if use_dialog_box; then
                    run_script 'menu_dialog_example' "Turned off borders" "${APPLICATION_COMMAND} --theme-no-borders"
                fi
                ;;
            *)
                error "Invalid option: '${C["UserCommand"]}${THEMEMETHOD-}${NC}'"
                exit 1
                ;;
        esac
        exit
    fi
    if [[ -n ${ADD-} ]]; then
        local CommandLine
        CommandLine="${APPLICATION_COMMAND} --add $(run_script 'app_nicename' "${ADD}")"
        run_script_dialog "Add Application" "${DC[NC]} ${DC["CommandLine"]}${CommandLine}${DC[NC]}" "" \
            'appvars_create' "${ADD}"
        run_script 'env_update'
        exit
    fi

    # Create the '.env' file if it doesn't exists before the following command-line options
    run_script 'env_create'

    if [[ -n ${COMPOSE-} ]]; then
        case ${COMPOSE} in
            generate | merge) ;&
            down | pull | stop | restart | update | up) ;&
            "down "* | "pull "* | "stop "* | "restart "* | "update "* | "up "*)
                run_script 'docker_compose' "${COMPOSE}"
                ;;
            *)
                error "Invalid compose option '${C["UserCommand"]}${COMPOSE}${NC}'."
                exit 1
                ;;
        esac
        exit
    fi
    if [[ -n ${ENVMETHOD-} ]]; then
        case "${ENVMETHOD-}" in
            env)
                run_script_dialog "${DC["TitleSuccess"]}Creating environment variables for added apps" "Please be patient, this can take a while.\n${DC["CommandLine"]} ${APPLICATION_COMMAND} --env" "" \
                    'appvars_create_all'
                exit
                ;;
            env-get)
                if [[ ${ENVVAR-} != "" ]]; then
                    if use_dialog_box; then
                        local CommandLine
                        CommandLine="${APPLICATION_COMMAND} --env-get ${ENVVAR^^}"
                        for VarName in $(xargs -n1 <<< "${ENVVAR}"); do
                            run_script 'env_get' "${VarName}"
                        done |& dialog_pipe "Get Value of Variable" "${DC[NC]} ${DC["CommandLine"]}${CommandLine}" ""
                    else
                        for VarName in $(xargs -n1 <<< "${ENVVAR^^}"); do
                            run_script 'env_get' "${VarName}"
                        done
                    fi
                else
                    echo "Invalid usage. Must be:"
                    echo "  '${C["UserCommand"]}${APPLICATION_COMMAND} --env-get${NC}' with variable name ('${C["UserCommand"]}${APPLICATION_COMMAND} --env-get VAR${NC}' or '${C["UserCommand"]}${APPLICATION_COMMAND} --env-get VAR [VAR ...]${NC}')"
                    echo "  Variable name will be forced to UPPER CASE"
                fi
                ;;
            env-get-lower)
                if [[ ${ENVVAR-} != "" ]]; then
                    if use_dialog_box; then
                        local CommandLine
                        CommandLine="${APPLICATION_COMMAND} --env-get-line ${ENVVAR}"
                        for VarName in $(xargs -n1 <<< "${ENVVAR}"); do
                            run_script 'env_get' "${VarName}"
                        done |& dialog_pipe "Get Value of Variable" "${DC[NC]} ${DC["CommandLine"]}${CommandLine}" ""
                    else
                        for VarName in $(xargs -n1 <<< "${ENVVAR}"); do
                            run_script 'env_get' "${VarName}"
                        done
                    fi
                else
                    echo "Invalid usage. Must be:"
                    echo "  '${C["UserCommand"]}${APPLICATION_COMMAND} --env-get-lower${NC}' with variable name ('${C["UserCommand"]}${APPLICATION_COMMAND} --env-get-lower=Var${NC}' or '${C["UserCommand"]}${APPLICATION_COMMAND} --env-get-lower Var [Var ...]${NC}')"
                    echo "  Variable name can be Mixed Case"
                fi
                ;;
            env-get-line)
                if [[ ${ENVVAR-} != "" ]]; then
                    if use_dialog_box; then
                        local CommandLine
                        CommandLine="${APPLICATION_COMMAND} --env-get-line ${ENVVAR^^}"
                        for VarName in $(xargs -n1 <<< "${ENVVAR^^}"); do
                            run_script 'env_get_line' "${VarName}"
                        done |& dialog_pipe "Get Line of Variable" "${DC[NC]} ${DC["CommandLine"]}${CommandLine}" ""
                    else
                        for VarName in $(xargs -n1 <<< "${ENVVAR^^}"); do
                            run_script 'env_get_line' "${VarName}"
                        done
                    fi
                else
                    echo "Invalid usage. Must be:"
                    echo "  '${C["UserCommand"]}${APPLICATION_COMMAND} --env-get-line${NC}' with variable name ('${C["UserCommand"]}${APPLICATION_COMMAND} --env-get-line VAR${NC}' or '${C["UserCommand"]}${APPLICATION_COMMAND} --env-get-line VAR [VAR ...]${NC}')"
                    echo "  Variable name will be forced to UPPER CASE"
                fi
                ;;
            env-get-lower-line)
                if [[ ${ENVVAR-} != "" ]]; then
                    if use_dialog_box; then
                        local CommandLine
                        CommandLine="${APPLICATION_COMMAND} --env-get-lower-line ${ENVVAR}"
                        for VarName in $(xargs -n1 <<< "${ENVVAR}"); do
                            run_script 'env_get_line' "${VarName}"
                        done |& dialog_pipe "Get Line of Variable" "${DC[NC]} ${DC["CommandLine"]}${CommandLine}" ""
                    else
                        for VarName in $(xargs -n1 <<< "${ENVVAR}"); do
                            run_script 'env_get_line' "${VarName}"
                        done
                    fi
                else
                    echo "Invalid usage. Must be:"
                    echo "  '${C["UserCommand"]}${APPLICATION_COMMAND} --env-get-lower-line${NC}' with variable name ('${C["UserCommand"]}${APPLICATION_COMMAND} --env-get-lower-line=Var${NC}' or '${C["UserCommand"]}${APPLICATION_COMMAND} --env-get-lower-line Var [Var ...]${NC}')"
                    echo "  Variable name can be Mixed Case"
                fi
                ;;
            env-get-literal)
                if [[ ${ENVVAR-} != "" ]]; then
                    if use_dialog_box; then
                        local CommandLine
                        CommandLine="${APPLICATION_COMMAND} --env-get-lower-literal ${ENVVAR^^}"
                        for VarName in $(xargs -n1 <<< "${ENVVAR^^}"); do
                            run_script 'env_get_literal' "${VarName}"
                        done |& dialog_pipe "Get Literal Value of Variable" "${DC[NC]} ${DC["CommandLine"]}${CommandLine}" ""
                    else
                        for VarName in $(xargs -n1 <<< "${ENVVAR^^}"); do
                            run_script 'env_get_literal' "${VarName}"
                        done
                    fi
                else
                    echo "Invalid usage. Must be:"
                    echo "  '${C["UserCommand"]}${APPLICATION_COMMAND} --env-get-literal${NC}' with variable name ('${C["UserCommand"]}${APPLICATION_COMMAND} --env-get-literal VAR${NC}' or '${C["UserCommand"]}${APPLICATION_COMMAND} --env-get-literal VAR [VAR ...]${NC}')"
                    echo "  Variable name will be forced to UPPER CASE"
                fi
                ;;
            env-get-lower-literal)
                if [[ ${ENVVAR-} != "" ]]; then
                    if use_dialog_box; then
                        local CommandLine
                        CommandLine="${APPLICATION_COMMAND} --env-get-lower-literal ${ENVVAR}"
                        for VarName in $(xargs -n1 <<< "${ENVVAR}"); do
                            run_script 'env_get_literal' "${VarName}"
                        done |& dialog_pipe "Get Literal Value of Variable" "${DC[NC]} ${DC["CommandLine"]}${CommandLine}" ""
                    else
                        for VarName in $(xargs -n1 <<< "${ENVVAR}"); do
                            run_script 'env_get_literal' "${VarName}"
                        done
                    fi
                else
                    echo "Invalid usage. Must be:"
                    echo "  '${C["UserCommand"]}${APPLICATION_COMMAND} --env-get-lower-literal${NC}' with variable name ('${C["UserCommand"]}${APPLICATION_COMMAND} --env-get-lower-literal=Var${NC}' or '${C["UserCommand"]}${APPLICATION_COMMAND} --env-get-lower-literal Var [Var ...]${NC}')"
                    echo "  Variable name can be Mixed Case"
                fi
                ;;
            env-set)
                if [[ ${ENVVAR-} != "" ]] && [[ ${ENVVAL-} != "" ]]; then
                    run_script 'env_backup'
                    run_script 'env_set' "${ENVVAR^^}" "${ENVVAL}"
                else
                    echo "Invalid usage. Must be:"
                    echo "  '${C["UserCommand"]}${APPLICATION_COMMAND} --env-set${NC}' with variable name and value ('${C["UserCommand"]}${APPLICATION_COMMAND} --env-set=VAR,VAL${NC}' or '${C["UserCommand"]}${APPLICATION_COMMAND} --env-set VAR=Val'${NC})"
                    echo "  Variable name will be forced to UPPER CASE"
                fi
                ;;
            env-set-lower)
                if [[ ${ENVVAR-} != "" ]] && [[ ${ENVVAL-} != "" ]]; then
                    run_script 'env_backup'
                    run_script 'env_set' "${ENVVAR}" "${ENVVAL}"
                else
                    echo "Invalid usage. Must be:"
                    echo "  '${C["UserCommand"]}${APPLICATION_COMMAND} --env-set-lower${NC}' with variable name and value ('${C["UserCommand"]}${APPLICATION_COMMAND} --env-set-lower=Var,VAL${NC}' or '${C["UserCommand"]}${APPLICATION_COMMAND} --env-set-lower Var=Val${NC}')"
                    echo "  Variable name can be Mixed Case"
                fi
                ;;
            env-appvars)
                if [[ ${ENVAPP-} != "" ]]; then
                    if use_dialog_box; then
                        local CommandLine
                        CommandLine="${APPLICATION_COMMAND} --env-appvars $(run_script 'app_nicename' "${ENVAPP}" | tr '\n' ' ')"
                        for AppName in $(xargs -n1 <<< "${ENVAPP}"); do
                            run_script 'appvars_list' "${AppName}"
                        done |& dialog_pipe "Variables for Application" "${DC[NC]} ${DC["CommandLine"]}${CommandLine}" ""
                    else
                        for AppName in $(xargs -n1 <<< "${ENVAPP^^}"); do
                            run_script 'appvars_list' "${AppName}"
                        done
                    fi
                else
                    echo "Invalid usage. Must be:"
                    echo "  '${C["UserCommand"]}${APPLICATION_COMMAND} --env-appvars${NC}' with application name ('${C["UserCommand"]}${APPLICATION_COMMAND} --env-appvars App [App ...]${NC}')"
                fi
                ;;
            env-appvars-lines)
                if [[ ${ENVAPP-} != "" ]]; then
                    if use_dialog_box; then
                        local CommandLine
                        CommandLine="${APPLICATION_COMMAND} --env-appvars-lines $(run_script 'app_nicename' "${ENVAPP}" | tr '\n' ' ')"
                        for AppName in $(xargs -n1 <<< "${ENVAPP}"); do
                            run_script 'appvars_lines' "${AppName}"
                        done |& dialog_pipe "Variable Lines for Application" "${DC[NC]} ${DC["CommandLine"]}${CommandLine}" ""
                    else
                        for AppName in $(xargs -n1 <<< "${ENVAPP}"); do
                            run_script 'appvars_lines' "${AppName}"
                        done
                    fi
                else
                    echo "Invalid usage. Must be:"
                    echo "  '${C["UserCommand"]}${APPLICATION_COMMAND} --env-appvars-lines${NC}' with application name ('${C["UserCommand"]}${APPLICATION_COMMAND} --env-appvars-lines App [App ...]'${NC})"
                fi
                ;;
            *)
                echo "Invalid option: '${C["UserCommand"]}${ENVMETHOD-}${NC}'"
                ;;
        esac
        exit
    fi
    if [[ -n ${LIST-} ]]; then
        run_script_dialog "List All Applications" "" "" \
            'app_list'
        exit
    fi
    if [[ -n ${LISTMETHOD-} ]]; then
        case "${LISTMETHOD-}" in
            list-builtin)
                run_script_dialog "List Builtin Applications" "" "" \
                    'app_nicename' "$(run_script 'app_list_builtin')"
                ;;
            list-deprecated)
                run_script_dialog "List Deprecated Applications" "" "" \
                    'app_nicename' "$(run_script 'app_list_deprecated')"
                ;;
            list-nondeprecated)
                run_script_dialog "List Non-Deprecated Applications" "" "" \
                    'app_nicename' "$(run_script 'app_list_nondeprecated')"
                ;;
            list-added)
                run_script_dialog "List Added Applications" "" "" \
                    'app_nicename' "$(run_script 'app_list_added')"
                ;;
            list-enabled)
                run_script_dialog "List Enabled Applications" "" "" \
                    'app_nicename' "$(run_script 'app_list_enabled')"
                ;;
            list-disabled)
                run_script_dialog "List Disabled Applications" "" "" \
                    'app_nicename' "$(run_script 'app_list_disabled')"
                ;;
            list-referenced)
                run_script_dialog "List Referenced Applications" "" "" \
                    'app_nicename' "$(run_script 'app_list_referenced')"
                ;;

            *)
                echo "Invalid option: '${C["UserCommand"]}${LISTMETHOD-}${NC}'"
                ;;
        esac
        exit
    fi
    if [[ -n ${REMOVE-} ]]; then
        if [[ ${REMOVE} == true ]]; then
            run_script 'appvars_purge_all'
            run_script 'env_update'
        else
            run_script 'appvars_purge' "${REMOVE}"
            run_script 'env_update'
        fi
        exit
    fi
    if [[ -n ${SELECT-} ]]; then
        PROMPT='GUI'
        run_script 'menu_app_select' || true
        exit
    fi
    if [[ -n ${STATUSMETHOD-} ]]; then
        case "${STATUSMETHOD-}" in
            status)
                local CommandLine
                CommandLine="${APPLICATION_COMMAND} --status $(run_script 'app_nicename' "${STATUS}" | tr '\n' ' ')"
                run_script_dialog "Application Status" "${DC[NC]} ${DC["CommandLine"]}${CommandLine}" "" \
                    'app_status' "${STATUS}"
                ;;
            status-enable)
                run_script 'enable_app' "${STATUS}"
                run_script 'env_update'
                ;;
            status-disable)
                run_script 'disable_app' "${STATUS}"
                run_script 'env_update'
                ;;
            *)
                echo "Invalid option: '${C["UserCommand"]}${STATUSMETHOD-}${NC}'"
                ;;
        esac
        exit
    fi
    # Run Menus
    if [[ -n ${DIALOG-} ]]; then
        MENU=true
        PROMPT="GUI"
        run_script 'menu_main'
    else
        error "The GUI requires the '${C["Program"]}dialog${NC}' command to be installed."
        error "'${C["Program"]}dialog${NC}' command not found. Run '${C["UserCommand"]}${APPLICATION_COMMAND} -fiv${NC}' to install all dependencies."
        fatal "Unable to start GUI without '${C["Program"]}dialog${NC}' command."
    fi

}
main
