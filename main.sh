#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -rx APPLICATION_NAME='DockSTARTer'
declare -rx SOURCE_BRANCH='master'
declare -rx TARGET_BRANCH='main'

export LC_ALL=C
export PROMPT="CLI"
export MENU=false

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
readonly COMPOSE_FOLDER_NAME="compose"
export COMPOSE_FOLDER_NAME
readonly COMPOSE_FOLDER="${SCRIPTPATH}/${COMPOSE_FOLDER_NAME}"
export COMPOSE_FOLDER
readonly COMPOSE_OVERRIDE_NAME="docker-compose.override.yml"
export COMPOSE_OVERRIDE_NAME
readonly COMPOSE_OVERRIDE="${COMPOSE_FOLDER}/${COMPOSE_OVERRIDE_NAME}"
export COMPOSE_OVERRIDE
readonly COMPOSE_ENV="${COMPOSE_FOLDER}/.env"
export COMPOSE_ENV
readonly COMPOSE_ENV_DEFAULT_FILE="${COMPOSE_FOLDER}/.env.example"
export COMPOSE_ENV_DEFAULT_FILE
readonly APP_ENV_FOLDER_NAME="env_files"
export APP_ENV_FOLDER_NAME
readonly APP_ENV_FOLDER="${COMPOSE_FOLDER}/env_files"
export APP_ENV_FOLDER
readonly TEMPLATES_FOLDER="${COMPOSE_FOLDER}/.apps"
export TEMPLATES_FOLDER
readonly INSTANCES_FOLDER="${COMPOSE_FOLDER}/.instances"
export INSTANCES_FOLDER
readonly THEME_FOLDER="${SCRIPTPATH}/.themes"
export THEME_FOLDER

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
    ["URL"]="${F[M]}${UL}"
    ["UserCommand"]="${F[Y]}${BD}"
    ["Var"]="${F[C]}"
    ["Version"]="${F[C]}"
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

declare -Ax DC=()
declare -x DIALOGOTS

# Log Functions
MKTEMP_LOG=$(mktemp) || echo -e "Failed to create temporary log file.\nFailing command: ${C["FailingCommand"]}mktemp"
readonly MKTEMP_LOG
echo "DockSTARTer Log" > "${MKTEMP_LOG}"
create_strip_log_colors_SEDSTRING() {
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
strip_log_colors_SEDSTRING="$(create_strip_log_colors_SEDSTRING)"
readonly strip_log_colors_SEDSTRING
strip_log_colors() {
    printf '%s' "$*" | sed -E "${strip_log_colors_SEDSTRING}"
}
log() {
    local TOTERM=${1-}
    local MESSAGE=${2-}
    local STRIPPED_MESSAGE
    STRIPPED_MESSAGE=$(strip_log_colors "${MESSAGE-}")
    if [[ -n ${TOTERM} ]]; then
        if [[ -t 2 ]]; then
            # Stderr is not being redirected, output with color
            echo -e "${MESSAGE-}" >&2
        else
            # Stderr is being redirected, output without colorr
            echo -e "${STRIPPED_MESSAGE-}" >&2
        fi
    fi
    # Output the message to the log file without color
    echo -e "${STRIPPED_MESSAGE-}" >> "${MKTEMP_LOG}"
}
trace() { log "${TRACE-}" "${NC}$(date +"%F %T") ${C["Trace"]}[TRACE ]${NC}   $*${NC}"; }
debug() { log "${DEBUG-}" "${NC}$(date +"%F %T") ${C["Debug"]}[DEBUG ]${NC}   $*${NC}"; }
info() { log "${VERBOSE-}" "${NC}$(date +"%F %T") ${C["Info"]}[INFO  ]${NC}   $*${NC}"; }
notice() { log true "${NC}$(date +"%F %T") ${C["Notice"]}[NOTICE]${NC}   $*${NC}"; }
warn() { log true "${NC}$(date +"%F %T") ${C["Warn"]}[WARN  ]${NC}   $*${NC}"; }
error() { log true "${NC}$(date +"%F %T") ${C["Error"]}[ERROR ]${NC}   $*${NC}"; }
fatal() {
    log true "${NC}$(date +"%F %T") ${C["Fatal"]}[FATAL ]${NC}   $*${NC}"
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
        fatal "Running as root is not supported. Please run as a standard user with sudo."
    fi
}

# Check if running with sudo
check_sudo() {
    if [[ ${EUID} -eq 0 ]]; then
        fatal "Running with sudo is not supported. Commands requiring sudo will prompt automatically when required."
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
        fatal "${SCRIPTPATH}/.scripts/${SCRIPTSNAME}.sh not found."
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

_dialog_() {
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
    BackTitle="${LeftBackTitle}${Indent}${RightBackTitle}"

    ${DIALOG} --backtitle "${BackTitle}" "$@"
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
        run_script "${SCRIPTSNAME}" "$@" |& dialog_pipe "${Title}" "${SubTitle}" "${TimeOut}"
        return "${PIPESTATUS[0]}"
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
            "${CommandName}" "$@" |& dialog_pipe "${Title}" "${SubTitle}" "${TimeOut}"
            return "${PIPESTATUS[0]}"
        else
            "${CommandName}" "$@"
            return
        fi
    fi
}

dialog_message() {
    local Title=${1:-}
    local Message=${2:-}
    local TimeOut=${3:-0}
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
Usage: ds [OPTION]
NOTE: ds shortcut is only available after the first run of
    bash main.sh

${APPLICATION_HEADING}
This is the main ${APPLICATION_NAME} script.
For regular usage you can run without providing any options.

Any command that takes a variable name, the variable name can also be in the
form of app:var to refer to the variable in env_files/app.env.  Some commands
that take app names can use the form app: to refer to the same file.

-a --add <app> [<app> ...]
    Add the default .env variables for the app(s) specified
-c --compose <pull/up/down/stop/restart/update> [<app> ...]
    Run docker compose commands. If no command is given, does an update.
    Update is the same as a 'pull' followed by an 'up'
-c --compose <generate/merge>
    Generates the docker-compose.yml file
-e --env
    Update your .env file with new variables
--env-appvars <app> [<app> ...]
    List all variable names for the app(s) specified
--env-appvars-lines <app> [<app> ...]
    List all variables and values for the app(s) specified
--env-get <var> [<var> ...]
--env-get=<var>
    Get the value of a <var>iable in .env (variable name is forced to UPPER CASE)
--env-get-line <var> [<var> ...]
--env-get-line=<var>
    Get the line of a <var>iable in .env (variable name is forced to UPPER CASE)
--env-get-literal <var> [<var> ...]
--env-get-literal=<var>
    Get the literal value (including quotes) of a <var>iable in .env (variable name is forced to UPPER CASE)
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
    Set the <val>ue of a <var>iable in .env (variable name is forced to UPPER CASE)
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
--list-depreciated
    List depreciated apps
--list-enabled
    List enabled apps
--list-disabled
    List disabled apps
--list-nondepreciated
    List depreciated apps
--list-referenced
    List referenced apps (whether they are "built in" or not)
    An app is considered "referenced" if there is a variable matching the app's name in the
    global .env file, or there are any variables in the file env_files/<appname>.env
-h --help
    Show this usage information
-i --install
    Install/update all dependencies
-p --prune
    Remove unused docker resources
-r --remove
    Prompt to remove .env variables for all disabled apps
-r --remove <appname>
    Prompt to remove the .env variables for the app specified
-s --status <appname>
    Returns the enabled/disabled status for the app specified
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
    sudo sh -c "cat ${MKTEMP_LOG:-/dev/null} >> ${SCRIPTPATH}/dockstarter.log" || true
    sudo rm -f "${MKTEMP_LOG-}" || true
    sudo sh -c "echo \"$(tail -1000 "${SCRIPTPATH}/dockstarter.log")\" > ${SCRIPTPATH}/dockstarter.log" || true
    sudo -E chmod +x "${SCRIPTNAME}" > /dev/null 2>&1 || true

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
    while getopts ":-:a:c:efghilpr:s:t:T:u:vV:x" OPTION; do
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
                    error "${OPTION} requires an option."
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
                            error "Invalid compose option ${OPTARG}."
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
                    warn "The '--gui' option requires the dialog command to be installed."
                    warn "'dialog' command not found. Run 'ds -fiv' to install all dependencies."
                    warn "Coninuing without '--gui' option."
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
                    error "${OPTION} requires an option."
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
                    error "${OPTION} requires an option."
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
                    error "${OPTION} requires an option."
                    exit 1
                fi
                ;;
            t | test)
                if [[ -n ${OPTARG-} ]]; then
                    readonly TEST=${OPTARG}
                else
                    error "${OPTION} requires an option."
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
                        error "${OPTARG} requires an option."
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
            notice "Testing ${SCRIPTSNAME}."
            # shellcheck source=/dev/null
            source "${SCRIPTPATH}/.scripts/${SCRIPTSNAME}.sh"
            "${TESTSNAME}" "$@" || fatal "Failed to run ${TESTSNAME}."
            notice "Completed testing ${TESTSNAME}."
        else
            fatal "Test function in ${SCRIPTPATH}/.scripts/${SCRIPTSNAME}.sh not found."
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
    DS_COMMAND=$(command -v ds || true)
    if [[ -L ${DS_COMMAND} ]]; then
        local DS_SYMLINK
        DS_SYMLINK=$(readlink -f "${DS_COMMAND}")
        if [[ ${SCRIPTNAME} != "${DS_SYMLINK}" ]]; then
            if check_repo; then
                if run_script 'question_prompt' "${PROMPT:-CLI}" N "${APPLICATION_NAME} installation found at ${DS_SYMLINK} location. Would you like to run ${SCRIPTNAME} instead?"; then
                    run_script 'symlink_ds'
                    DS_COMMAND=$(command -v ds || true)
                    DS_SYMLINK=$(readlink -f "${DS_COMMAND}")
                fi
            fi
            warn "Attempting to run ${APPLICATION_NAME} from ${DS_SYMLINK} location."
            bash "${DS_SYMLINK}" -fvu
            bash "${DS_SYMLINK}" -fvi
            exec bash "${DS_SYMLINK}" "${ARGS[@]-}"
        fi
    else
        if ! check_repo; then
            warn "Attempting to clone ${APPLICATION_NAME} repo to ${DETECTED_HOMEDIR}/.docker location."
            git clone https://github.com/GhostWriters/DockSTARTer "${DETECTED_HOMEDIR}/.docker" || fatal "Failed to clone ${APPLICATION_NAME} repo.\nFailing command: ${C["FailingCommand"]}git clone https://github.com/GhostWriters/DockSTARTer \"${DETECTED_HOMEDIR}/.docker\""
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
            warn "Run '${C["UserCommand"]}ds -u${NC}' to update to version ${C["Version"]}$(ds_version "${Branch}")${NC}."
        else
            info "${APPLICATION_NAME} [${C["Version"]}${APPLICATION_VERSION}${NC}]"
        fi
    else
        local MainBranch="${TARGET_BRANCH}"
        if ! ds_branch_exists "${MainBranch}"; then
            MainBranch="${SOURCE_BRANCH}"
        fi
        warn "${APPLICATION_NAME} branch '${C["Branch"]}${Branch}${NC}' appears to no longer exist."
        warn "${APPLICATION_NAME} is currently on version ${C["Version"]}$(ds_version)${NC}."
        if ! ds_branch_exists "${MainBranch}"; then
            error "${APPLICATION_NAME} does not appear to have a '${C["Branch"]}${TARGET_BRANCH}${NC}' or '${C["Branch"]}${SOURCE_BRANCH}${NC}' branch."
        else
            warn "Run '${C["UserCommand"]}ds -u ${MainBranch}${NC}' to update to the latest stable release ${C["Version"]}$(ds_version "${MainBranch}")${NC}."
        fi
    fi
    # Check if we're running a test
    if [[ -n ${TEST-} ]]; then
        run_test "${TEST}"
        exit
    fi

    # Apply the GUI theme
    run_script 'apply_theme'
    # Create the .env file if it doesn't exists
    run_script 'env_create'

    # Execute CLI Argument Functions
    if [[ -n ${ADD-} ]]; then
        run_script_dialog "Add Application" "$(highlighted_list "$(run_script 'app_nicename' "${ADD}")")" "" \
            'appvars_create' "${ADD}"
        run_script 'env_update'
        exit
    fi
    if [[ -n ${COMPOSE-} ]]; then
        case ${COMPOSE} in
            generate | merge) ;&
            down | pull | stop | restart | update | up) ;&
            "down "* | "pull "* | "stop "* | "restart "* | "update "* | "up "*)
                run_script 'docker_compose' "${COMPOSE}"
                ;;
            *)
                fatal "Invalid compose option."
                ;;
        esac
        exit
    fi
    if [[ -n ${ENVMETHOD-} ]]; then
        case "${ENVMETHOD-}" in
            env)
                run_script_dialog "${DC["TitleSuccess"]}Creating environment variables for added apps" "Please be patient, this can take a while.\n${DC["CommandLine"]} ds --env" "" \
                    'appvars_create_all'
                exit
                ;;
            env-get)
                if [[ ${ENVVAR-} != "" ]]; then
                    if use_dialog_box; then
                        for VarName in $(xargs -n1 <<< "${ENVVAR^^}"); do
                            run_script 'env_get' "${VarName}"
                        done |& dialog_pipe "Get Value of Variable" "$(highlighted_list "${ENVVAR^^}")" ""
                    else
                        for VarName in $(xargs -n1 <<< "${ENVVAR^^}"); do
                            run_script 'env_get' "${VarName}"
                        done
                    fi
                else
                    echo "Invalid usage. Must be"
                    echo "  --env-get with variable name ('--env-get VAR' or '--env-get VAR [VAR ...]')"
                    echo "  Variable name will be forced to UPPER CASE"
                fi
                ;;
            env-get-lower)
                if [[ ${ENVVAR-} != "" ]]; then
                    if use_dialog_box; then
                        for VarName in $(xargs -n1 <<< "${ENVVAR}"); do
                            run_script 'env_get' "${VarName}"
                        done |& dialog_pipe "Get Value of Variable" "$(highlighted_list "${ENVVAR}")" ""
                    else
                        for VarName in $(xargs -n1 <<< "${ENVVAR}"); do
                            run_script 'env_get' "${VarName}"
                        done
                    fi
                else
                    echo "Invalid usage. Must be"
                    echo "  --env-get-lower with variable name ('--env-get-lower=Var' or '--env-get-lower Var [Var ...]')"
                    echo "  Variable name can be Mixed Case"
                fi
                ;;
            env-get-line)
                if [[ ${ENVVAR-} != "" ]]; then
                    if use_dialog_box; then
                        for VarName in $(xargs -n1 <<< "${ENVVAR^^}"); do
                            run_script 'env_get_line' "${VarName}"
                        done |& dialog_pipe "Get Line of Variable" "$(highlighted_list "${ENVVAR^^}")" ""
                    else
                        for VarName in $(xargs -n1 <<< "${ENVVAR^^}"); do
                            run_script 'env_get_line' "${VarName}"
                        done
                    fi
                else
                    echo "Invalid usage. Must be"
                    echo "  --env-get-line with variable name ('--env-get-line VAR' or '--env-get-line VAR [VAR ...]')"
                    echo "  Variable name will be forced to UPPER CASE"
                fi
                ;;
            env-get-lower-line)
                if [[ ${ENVVAR-} != "" ]]; then
                    if use_dialog_box; then
                        for VarName in $(xargs -n1 <<< "${ENVVAR}"); do
                            run_script 'env_get_line' "${VarName}"
                        done |& dialog_pipe "Get Line of Variable" "$(highlighted_list "${ENVVAR}")" ""
                    else
                        for VarName in $(xargs -n1 <<< "${ENVVAR}"); do
                            run_script 'env_get_line' "${VarName}"
                        done
                    fi
                else
                    echo "Invalid usage. Must be"
                    echo "  --env-get-lower-line with variable name ('--env-get-lower-line=Var' or '--env-get-lower-line Var [Var ...]')"
                    echo "  Variable name can be Mixed Case"
                fi
                ;;
            env-get-literal)
                if [[ ${ENVVAR-} != "" ]]; then
                    if use_dialog_box; then
                        for VarName in $(xargs -n1 <<< "${ENVVAR^^}"); do
                            run_script 'env_get_literal' "${VarName}"
                        done |& dialog_pipe "Get Literal Value of Variable" "$(highlighted_list "${ENVVAR^^}")" ""
                    else
                        for VarName in $(xargs -n1 <<< "${ENVVAR^^}"); do
                            run_script 'env_get_literal' "${VarName}"
                        done
                    fi
                else
                    echo "Invalid usage. Must be"
                    echo "  --env-get-literal with variable name ('--env-get-literal VAR' or '--env-get-literal VAR [VAR ...]')"
                    echo "  Variable name will be forced to UPPER CASE"
                fi
                ;;
            env-get-lower-literal)
                if [[ ${ENVVAR-} != "" ]]; then
                    if use_dialog_box; then
                        for VarName in $(xargs -n1 <<< "${ENVVAR}"); do
                            run_script 'env_get_literal' "${VarName}"
                        done |& dialog_pipe "Get Literal Value of Variable" "$(highlighted_list "${ENVVAR}")" ""
                    else
                        for VarName in $(xargs -n1 <<< "${ENVVAR}"); do
                            run_script 'env_get_literal' "${VarName}"
                        done
                    fi
                else
                    echo "Invalid usage. Must be"
                    echo "  --env-get-lower-literal with variable name ('--env-get-lower-literal=Var' or '--env-get-lower-literal Var [Var ...]')"
                    echo "  Variable name can be Mixed Case"
                fi
                ;;
            env-set)
                if [[ ${ENVVAR-} != "" ]] && [[ ${ENVVAL-} != "" ]]; then
                    run_script 'env_backup'
                    run_script 'env_set' "${ENVVAR^^}" "${ENVVAL}"
                else
                    echo "Invalid usage. Must be"
                    echo "  --env-set with variable name and value ('--env-set=VAR,VAL' or '--env-set VAR=Val')"
                    echo "  Variable name will be forced to UPPER CASE"
                fi
                ;;
            env-set-lower)
                if [[ ${ENVVAR-} != "" ]] && [[ ${ENVVAL-} != "" ]]; then
                    run_script 'env_backup'
                    run_script 'env_set' "${ENVVAR}" "${ENVVAL}"
                else
                    echo "Invalid usage. Must be"
                    echo "  --env-set-lower with variable name and value ('--env-set-lower=Var,VAL' or '--env-set-lower Var=Val')"
                    echo "  Variable name can be Mixed Case"
                fi
                ;;
            env-appvars)
                if [[ ${ENVAPP-} != "" ]]; then
                    if use_dialog_box; then
                        for AppName in $(xargs -n1 <<< "${ENVAPP^^}"); do
                            run_script 'appvars_list' "${AppName}"
                        done |& dialog_pipe "Variables for Application" "$(highlighted_list "$(run_script 'app_nicename' "${ENVAPP}")")" ""
                    else
                        for AppName in $(xargs -n1 <<< "${ENVAPP^^}"); do
                            run_script 'appvars_list' "${AppName}"
                        done
                    fi
                else
                    echo "Invalid usage. Must be"
                    echo "  --env-appvars with application name ('--env-appvars App [App ...]')"
                fi
                ;;
            env-appvars-lines)
                if [[ ${ENVAPP-} != "" ]]; then
                    if use_dialog_box; then
                        for AppName in $(xargs -n1 <<< "${ENVAPP^^}"); do
                            run_script 'appvars_lines' "${AppName}"
                        done |& dialog_pipe "Variable Lines for Application" "$(highlighted_list "$(run_script 'app_nicename' "${ENVAPP}")")" ""
                    else
                        for AppName in $(xargs -n1 <<< "${ENVAPP^^}"); do
                            run_script 'appvars_lines' "${AppName}"
                        done
                    fi
                else
                    echo "Invalid usage. Must be"
                    echo "  --env-appvars-lines with application name ('--env-appvars-lines App [App ...]')"
                fi
                ;;
            *)
                echo "Invalid option: '${ENVMETHOD-}'"
                ;;
        esac
        exit
    fi
    if [[ -n ${INSTALL-} ]]; then
        run_script 'run_install'
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
            list-depreciated)
                run_script_dialog "List Depreciated Applications" "" "" \
                    'app_nicename' "$(run_script 'app_list_depreciated')"
                ;;
            list-nondepreciated)
                run_script_dialog "List Non-Depreciated Applications" "" "" \
                    'app_nicename' "$(run_script 'app_list_nondepreciated')"
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
                echo "Invalid option: '${LISTMETHOD-}'"
                ;;
        esac
        exit
    fi
    if [[ -n ${PRUNE-} ]]; then
        run_script 'docker_prune'
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
    if [[ -n ${STATUSMETHOD-} ]]; then
        case "${STATUSMETHOD-}" in
            status)
                run_script_dialog "Application Status" "$(highlighted_list "$(run_script 'app_nicename' "${STATUS}")")" "" \
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
                echo "Invalid option: '${STATUSMETHOD-}'"
                ;;
        esac
        exit
    fi
    if [[ -n ${THEMEMETHOD-} ]]; then
        case "${THEMEMETHOD}" in
            theme)
                local NoticeText
                local CommandLine
                if [[ -n ${THEME-} ]]; then
                    NoticeText="Applying ${APPLICATION_NAME} theme ${C["Theme"]}${THEME}${NC}"
                    CommandLine="ds --theme \"${THEME}\""
                else
                    NoticeText="Applying ${APPLICATION_NAME} theme ${C["Theme"]}$(run_script 'theme_name')${NC}"
                    CommandLine="ds --theme"
                fi
                notice "${NoticeText}"
                run_script 'apply_theme' "${THEME-}"
                if use_dialog_box; then
                    run_script 'menu_dialog_example' "" "${CommandLine}"
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
                run_script 'env_set' Shadow yes "${MENU_INI_FILE}"
                if use_dialog_box; then
                    run_script 'menu_dialog_example' "Turned on shadows" "ds --theme-shadow"
                fi
                ;;
            theme-no-shadow)
                run_script 'env_set' Shadow no "${MENU_INI_FILE}"
                notice "Turning off GUI shadows."
                if use_dialog_box; then
                    run_script 'menu_dialog_example' "Turned off shadows" "ds --theme-no-shadow"
                fi
                ;;
            theme-scrollbar)
                run_script 'env_set' Scrollbar yes "${MENU_INI_FILE}"
                notice "Turning on GUI scrollbars."
                if use_dialog_box; then
                    run_script 'menu_dialog_example' "Turned on scrollbars" "ds --theme-scrollbar"
                fi
                ;;
            theme-no-scrollbar)
                run_script 'env_set' Scrollbar no "${MENU_INI_FILE}"
                notice "Turning off GUI scrollbars."
                if use_dialog_box; then
                    run_script 'menu_dialog_example' "Turned off scrollbars" "ds --theme-no-scrollbar"
                fi
                ;;
            theme-lines)
                run_script 'env_set' LineCharacters yes "${MENU_INI_FILE}"
                notice "Turning on GUI line drawing characters."
                if use_dialog_box; then
                    run_script 'menu_dialog_example' "Turned on line drawing" "ds --theme-lines"
                fi
                ;;
            theme-no-lines)
                notice "Turning off GUI line drawing characters."
                run_script 'env_set' LineCharacters no "${MENU_INI_FILE}"
                if use_dialog_box; then
                    run_script 'menu_dialog_example' "Turned off line drawing" "ds --theme-no-lines"
                fi
                ;;
            theme-borders)
                run_script 'env_set' Borders yes "${MENU_INI_FILE}"
                notice "Turning on GUI borders."
                if use_dialog_box; then
                    run_script 'menu_dialog_example' "Turned on borders" "ds --theme-borders"
                fi
                ;;
            theme-no-borders)
                notice "Turning off GUI borders."
                run_script 'env_set' Borders no "${MENU_INI_FILE}"
                if use_dialog_box; then
                    run_script 'menu_dialog_example' "Turned off borders" "ds --theme-no-borders"
                fi
                ;;
            *)
                echo "Invalid option: '${THEMEMETHOD-}'"
                ;;
        esac
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
            error "DockSTARTer branch '${C["Branch"]}${Branch}${NC}' does not exist."
        fi
        exit
    fi
    # Run Menus
    if [[ -n ${DIALOG-} ]]; then
        MENU=true
        PROMPT="GUI"
        run_script 'menu_main'
    else
        error "The GUI requires the dialog command to be installed."
        error "'dialog' command not found. Run 'ds -fiv' to install all dependencies."
        fatal "Unable to start GUI without dialog command."
    fi

}
main
