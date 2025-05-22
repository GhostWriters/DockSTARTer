#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

export LC_ALL=C
export PROMPT="CLI"
export MENU=false

usage() {
    cat << EOF
Usage: ds [OPTION]
NOTE: ds shortcut is only available after the first run of
    bash main.sh

This is the main DockSTARTer script.
For regular usage you can run without providing any options.

Any command that takes a variable name, the variable name can also be in the form of app:var
to refer to the variable in env_files/app.env.  Some commands that take app names can use the
form app: to refer to the same file.

-a --add <appname> [<appname> ...]
    add the default .env variables for the app specified
-c --compose
    run docker compose up with confirmation prompt
-c --compose <up/down/restart/pull>
    run docker compose commands without confirmation prompts
-e --env
    update your .env file with new variables
--env-appvars <app> [<app> ...]
    List all variable names for the app specified
--env-appvars-lines <app> [<app> ...]
    List all variables and values for the app specified
--env-get <var> [<var> ...]
--env-get=<var>
    get the value of a <var>iable in .env (variable name is forced to UPPER CASE)
--env-get-line <var> [<var> ...]
--env-get-line=<var>
    get the line of a <var>iable in .env (variable name is forced to UPPER CASE)
--env-get-literal <var> [<var> ...]
--env-get-literal=<var>
    get the literal value (including quotes) of a <var>iable in .env (variable name is forced to UPPER CASE)
--env-get-lower <var> [<var> ...]
--env-get-lower=<var>
    get the value of a <var>iable in .env
--env-get-lower-line <var> [<var> ...]
--env-get-lower-line=<var>
    get the line of a <var>iable in .env
--env-get-lower-literal <var> [<var> ...]
--env-get-lower-literal a <var>iable in .env
    get the literal value (including quotes) of a <var>iable in .env
--env-set <var>=<val>
--env-set=<var>,<val>
    Set the <val>ue of a <var>iable in .env (variable name is forced to UPPER CASE)
--env-set-lower <var>=<val>
--env-set-lower=<var>,<val>
    Set the <val>ue of a <var>iable in .env
-f --force
    force certain install/upgrade actions to run even if they would not be needed
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
-h --help
    show this usage information
-i --install
    install/update all dependencies
-p --prune
    remove unused docker resources
-r --remove
    prompt to remove .env variables for all disabled apps
-r --remove <appname>
    prompt to remove the .env variables for the app specified
-s --status <appname>
    Returns the enabled/disabled status for the app specified
--status-disabled <appname>
    Disable the app specified
--status-enabled <appname>
    Enable the app specified
-t --test <test_name>
    run tests to check the program
-u --update
    update DockSTARTer to the latest stable commits
-u --update <branch>
    update DockSTARTer to the latest commits from the specified branch
-v --verbose
    verbose
-x --debug
    debug
EOF
}

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

declare -rx DIALOGRC="${SCRIPTPATH}/.dialogrc"
declare -rx BACKTITLE="DockSTARTer"

DIALOG=$(command -v dialog) || true
export DIALOG
declare -rx DIALOGOPTS="--backtitle ${BACKTITLE} --cr-wrap --no-collapse"
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
        echo "DockSTARTer did not finish running successfully."
    fi

    exit ${EXIT_CODE}
}
trap 'cleanup' ERR EXIT SIGABRT SIGALRM SIGHUP SIGINT SIGQUIT SIGTERM

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
NC=$(tput sgr0 2> /dev/null || echo -e "\e[0m")
readonly NC
BS=$(tput cup 1000 0 2> /dev/null || true) # Bottom of screen
readonly BS
export BS

declare -Ag DC=( # Dialog colors
    [B]='\Z4'   # Blue
    [C]='\Z6'   # Cyan
    [G]='\Z2'   # Green
    [K]='\Z0'   # Black
    [M]='\Z5'   # Magenta
    [R]='\Z1'   # Red
    [W]='\Z7'   # White
    [Y]='\Z3'   # Yellow
    [RV]='\Zr'  # Reverse
    [NRV]='\ZR' # No Reverse
    [BD]='\Zb'  # Bold
    [NBD]='\ZB' # No Bold
    [U]='\Zu'   # Underline
    [NU]='\ZU'  # No Underline
    [NC]='\Zn'  # No Color
)
DC+=( # Pre-defined color combinations used in the GUI
    [Heading]="${DC[NC]}${DC[RV]}"
    [HeadingTag]="${DC[NC]}${DC[RV]}${DC[W]}"
    [HeadingValue]="${DC[NC]}${DC[BD]}${DC[RV]}"
    [Highlight]="${DC[NC]}${DC[Y]}${DC[BD]}"
    [LineHeading]="${DC[NC]}"
    [LineComment]="${DC[NC]}${DC[K]}${DC[BD]}${DC[RV]}"
    [LineOther]="${DC[NC]}${DC[K]}${DC[BD]}${DC[RV]}"
    [LineVar]="${DC[NC]}${DC[K]}${DC[NBD]}${DC[RV]}"
    [LineAddVariable]="${DC[NC]}${DC[K]}${DC[NBD]}${DC[RV]}"
)
readonly DC
declare -rix DIALOGTIMEOUT=3

# Log Functions
MKTEMP_LOG=$(mktemp) || echo -e "Failed to create temporary log file.\nFailing command: ${F[C]}mktemp"
readonly MKTEMP_LOG
echo "DockSTARTer Log" > "${MKTEMP_LOG}"
create_strip_log_colors_SEDSTRING() {
    # Create the search string to strip ANSI colors
    # String is saved after creation, so this is only done on the first call
    local -a ANSICOLORS=("${F[@]}" "${B[@]}" "${NC}")
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
trace() { log "${TRACE-}" "${NC}$(date +"%F %T") ${F[B]}[TRACE ]${NC}   $*${NC}"; }
debug() { log "${DEBUG-}" "${NC}$(date +"%F %T") ${F[B]}[DEBUG ]${NC}   $*${NC}"; }
info() { log "${VERBOSE-}" "${NC}$(date +"%F %T") ${F[B]}[INFO  ]${NC}   $*${NC}"; }
notice() { log true "${NC}$(date +"%F %T") ${F[G]}[NOTICE]${NC}   $*${NC}"; }
warn() { log true "${NC}$(date +"%F %T") ${F[Y]}[WARN  ]${NC}   $*${NC}"; }
error() { log true "${NC}$(date +"%F %T") ${F[R]}[ERROR ]${NC}   $*${NC}"; }
fatal() {
    log true "${NC}$(date +"%F %T") ${B[R]}${F[W]}[FATAL ]${NC}   $*${NC}"
    exit 1
}

# Command Line Arguments
readonly ARGS=("$@")
cmdline() {
    # http://www.kfirlavi.com/blog/2012/11/14/defensive-bash-programming/
    # http://kirk.webfinish.com/2009/10/bash-shell-script-to-use-getopts-with-gnu-style-long-positional-parameters/
    local ARG=
    local LOCAL_ARGS
    for ARG; do
        local DELIM=""
        case "${ARG}" in
            #translate --gnu-long-options to -g (short options)
            --add) LOCAL_ARGS="${LOCAL_ARGS-}-a " ;;
            --compose) LOCAL_ARGS="${LOCAL_ARGS-}-c " ;;
            --debug) LOCAL_ARGS="${LOCAL_ARGS-}-x " ;;
            --env)
                readonly ENVMETHOD=${ARG}
                LOCAL_ARGS="${LOCAL_ARGS-}-e "
                ;;
            --env-get=* | --env-get-lower=* | --env-get-line=* | --env-get-lower-line=* | --env-get-literal=* | --env-get-lower-literal=*)
                readonly ENVMETHOD=${ARG%%=*}
                readonly ENVARG=${ARG#*=}
                if [[ ${ENVMETHOD-} != "${ENVARG-}" ]]; then
                    readonly ENVVAR=${ENVARG}
                fi
                LOCAL_ARGS="${LOCAL_ARGS-}-e "
                ;;
            --env-set=* | --env-set-lower=*)
                readonly ENVMETHOD=${ARG%%=*}
                readonly ENVARG=${ARG#*=}
                if [[ ${ENVMETHOD-} != "${ENVARG-}" ]]; then
                    readonly ENVVAR=${ENVARG%%,*}
                    readonly ENVVAL=${ENVARG#*,}
                fi
                LOCAL_ARGS="${LOCAL_ARGS-}-e "
                ;;
            --env-get | --env-get-lower | --env-get-line | --env-get-lower-line | --env-get-literal | --env-get-lower-literal)
                readonly ENVMETHOD=${ARG}
                LOCAL_ARGS="${LOCAL_ARGS-}-e "
                ;;
            --env-set | --env-set-lower)
                readonly ENVMETHOD=${ARG}
                LOCAL_ARGS="${LOCAL_ARGS-}-e "
                ;;
            --env-appvars | --env-appvars-lines)
                readonly ENVMETHOD=${ARG}
                LOCAL_ARGS="${LOCAL_ARGS-}-e "
                ;;
            --force) LOCAL_ARGS="${LOCAL_ARGS-}-f " ;;
            --gui) LOCAL_ARGS="${LOCAL_ARGS-}-g " ;;
            --help) LOCAL_ARGS="${LOCAL_ARGS-}-h " ;;
            --install) LOCAL_ARGS="${LOCAL_ARGS-}-i " ;;
            --list) LOCAL_ARGS="${LOCAL_ARGS-}-l " ;;
            --list-*)
                readonly LISTMETHOD=${ARG%%=*}
                ;;
            --prune) LOCAL_ARGS="${LOCAL_ARGS-}-p " ;;
            --remove) LOCAL_ARGS="${LOCAL_ARGS-}-r " ;;
            --status)
                LOCAL_ARGS="${LOCAL_ARGS-}-s "
                readonly STATUSMETHOD=${ARG}
                ;;
            --status-*)
                LOCAL_ARGS="${LOCAL_ARGS-}-s "
                readonly STATUSMETHOD=${ARG}
                ;;
            --test) LOCAL_ARGS="${LOCAL_ARGS-}-t " ;;
            --update) LOCAL_ARGS="${LOCAL_ARGS-}-u " ;;
            --verbose) LOCAL_ARGS="${LOCAL_ARGS-}-v " ;;
            #pass through anything else
            *)
                [[ ${ARG:0:1} == "-" ]] || DELIM='"'
                LOCAL_ARGS="${LOCAL_ARGS-}${DELIM}${ARG}${DELIM} "
                ;;
        esac
    done

    #Reset the positional parameters to the short options
    eval set -- "${LOCAL_ARGS-}"

    while getopts ":a:c:e:fghilpr:s:t:u:vx" OPTION; do
        case ${OPTION} in
            a)
                local MULTIOPT
                MULTIOPT=("$OPTARG")
                until [[ $(eval "echo \${$OPTIND}" 2> /dev/null) =~ ^-.* ]] || [[ -z $(eval "echo \${$OPTIND}" 2> /dev/null) ]]; do
                    MULTIOPT+=("$(eval "echo \${$OPTIND}")")
                    OPTIND=$((OPTIND + 1))
                done
                ADD=$(printf "%s " "${MULTIOPT[@]}" | xargs)
                readonly ADD
                ;;
            c)
                case ${OPTARG} in
                    down | generate | merge | pull* | restart* | up*)
                        local MULTIOPT
                        MULTIOPT=("$OPTARG")
                        until [[ $(eval "echo \${$OPTIND}" 2> /dev/null) =~ ^-.* ]] || [[ -z $(eval "echo \${$OPTIND}" 2> /dev/null) ]]; do
                            MULTIOPT+=("$(eval "echo \${$OPTIND}")")
                            OPTIND=$((OPTIND + 1))
                        done
                        COMPOSE=$(printf "%s " "${MULTIOPT[@]}" | xargs)
                        readonly COMPOSE
                        ;;
                    *)
                        echo "Invalid compose option."
                        exit 1
                        ;;
                esac
                ;;
            e)
                case ${ENVMETHOD} in
                    --env) ;;
                    --env-appvars | --env-appvars-lines)
                        local MULTIOPT
                        MULTIOPT=("$OPTARG")
                        until [[ $(eval "echo \${$OPTIND}" 2> /dev/null) =~ ^-.* ]] || [[ -z $(eval "echo \${$OPTIND}" 2> /dev/null) ]]; do
                            MULTIOPT+=("$(eval "echo \${$OPTIND}")")
                            OPTIND=$((OPTIND + 1))
                        done
                        ENVAPP=$(printf "%s " "${MULTIOPT[@]}" | xargs)
                        readonly ENVAPP
                        ;;
                    --env-get | --env-get-lower | --env-get-line | --env-get-lower-line | --env-get-literal | --env-get-lower-literal)
                        if [[ -z ${ENVVAR-} ]]; then
                            local MULTIOPT
                            MULTIOPT=("$OPTARG")
                            until [[ $(eval "echo \${$OPTIND}" 2> /dev/null) =~ ^-.* ]] || [[ -z $(eval "echo \${$OPTIND}" 2> /dev/null) ]]; do
                                MULTIOPT+=("$(eval "echo \${$OPTIND}")")
                                OPTIND=$((OPTIND + 1))
                            done
                            ENVVAR=$(printf "%s " "${MULTIOPT[@]}" | xargs)
                            readonly ENVVAR
                        fi
                        ;;
                    --env-set | --env-set-lower)
                        if [[ -z ${ENVVAR-} ]]; then
                            readonly ENVARG=${OPTARG}
                            readonly ENVVAR=${ENVARG%%=*}
                            readonly ENVVAL=${ENVARG#*=}
                        fi
                        ;;
                esac
                ;;
            f)
                readonly FORCE=true
                export FORCE
                ;;
            g)
                if [[ -n ${DIALOG-} ]]; then
                    PROMPT="GUI"
                else
                    warn "The '--gui' option requires the dialog command to be installed."
                    warn "'dialog' command not found. Run 'ds -fiv' to install all dependencies."
                    warn "Coninuing without '--gui' option."
                fi
                ;;
            h)
                usage
                exit
                ;;
            i)
                readonly INSTALL=true
                ;;
            l)
                readonly LIST=true
                ;;
            p)
                readonly PRUNE=true
                ;;
            r)
                local MULTIOPT
                MULTIOPT=("$OPTARG")
                until [[ $(eval "echo \${$OPTIND}" 2> /dev/null) =~ ^-.* ]] || [[ -z $(eval "echo \${$OPTIND}" 2> /dev/null) ]]; do
                    MULTIOPT+=("$(eval "echo \${$OPTIND}")")
                    OPTIND=$((OPTIND + 1))
                done
                REMOVE=$(printf "%s " "${MULTIOPT[@]}" | xargs)
                readonly REMOVE
                ;;
            s)
                local MULTIOPT
                MULTIOPT=("$OPTARG")
                until [[ $(eval "echo \${$OPTIND}" 2> /dev/null) =~ ^-.* ]] || [[ -z $(eval "echo \${$OPTIND}" 2> /dev/null) ]]; do
                    MULTIOPT+=("$(eval "echo \${$OPTIND}")")
                    OPTIND=$((OPTIND + 1))
                done
                STATUS=$(printf "%s " "${MULTIOPT[@]}" | xargs)
                readonly STATUS
                ;;
            t)
                readonly TEST=${OPTARG}
                ;;
            u)
                readonly UPDATE=${OPTARG}
                ;;
            v)
                readonly VERBOSE=1
                ;;
            x)
                readonly DEBUG=1
                set -x
                ;;
            :)
                case ${OPTARG} in
                    c)
                        readonly COMPOSE=up
                        ;;
                    e)
                        if [[ -z ${ENVMETHOD-} ]]; then
                            readonly ENVMETHOD="--env"
                        fi
                        ;;
                    r)
                        readonly REMOVE=true
                        ;;
                    u)
                        readonly UPDATE=true
                        ;;
                    *)
                        echo "${OPTARG} requires an option."
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
cmdline "${ARGS[@]-}"
if [[ -n ${DEBUG-} ]] && [[ -n ${VERBOSE-} ]]; then
    readonly TRACE=1
fi

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
    else
        fatal "${SCRIPTPATH}/.scripts/${SCRIPTSNAME}.sh not found."
    fi
}

# Take whitespace and newline delimited words and output a single line highlited list for dialog
highlighted_list() {
    local List
    List=$(xargs <<< "$*")
    if [[ -n ${List-} ]]; then
        echo "${DC[RV]}${List// /${DC[NC]} ${DC[RV]}}${DC[NC]}"
    fi
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
    dialog --begin 2 2 --colors --timeout "${TimeOut}" --title "${Title}" --programbox "${DC[RV]}${SubTitle}${DC[NC]}" $((LINES - 4)) $((COLUMNS - 5)) || true
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
                if run_script 'question_prompt' "${PROMPT:-CLI}" N "DockSTARTer installation found at ${DS_SYMLINK} location. Would you like to run ${SCRIPTNAME} instead?"; then
                    run_script 'symlink_ds'
                    DS_COMMAND=$(command -v ds || true)
                    DS_SYMLINK=$(readlink -f "${DS_COMMAND}")
                fi
            fi
            warn "Attempting to run DockSTARTer from ${DS_SYMLINK} location."
            bash "${DS_SYMLINK}" -vu
            bash "${DS_SYMLINK}" -vi
            exec bash "${DS_SYMLINK}" "${ARGS[@]-}"
        fi
    else
        if ! check_repo; then
            warn "Attempting to clone DockSTARTer repo to ${DETECTED_HOMEDIR}/.docker location."
            git clone https://github.com/GhostWriters/DockSTARTer "${DETECTED_HOMEDIR}/.docker" || fatal "Failed to clone DockSTARTer repo.\nFailing command: ${F[C]}git clone https://github.com/GhostWriters/DockSTARTer \"${DETECTED_HOMEDIR}/.docker\""
            notice "Performing first run install."
            exec bash "${DETECTED_HOMEDIR}/.docker/main.sh" "-vi"
        fi
    fi
    # Create Symlink
    run_script 'symlink_ds'
    # Execute CLI Argument Functions
    if [[ -n ${ADD-} ]]; then
        run_script 'env_migrate_global'
        run_script_dialog "Add Application" "$(highlighted_list "$(run_script 'app_nicename' "${ADD}")")" "" \
            'appvars_create' "${ADD}"
        run_script 'env_update'
        exit
    fi
    if [[ -n ${COMPOSE-} ]]; then
        case ${COMPOSE} in
            down)
                run_script_dialog "Docker Compose" "${COMPOSE}" "" \
                    'docker_compose' "${COMPOSE}"
                ;;
            generate | merge)
                run_script_dialog "Docker Compose Merge" "" "" \
                    'yml_merge'
                ;;
            pull* | restart* | up*)
                run_script_dialog "Docker Compose" "${COMPOSE}" "" \
                    'merge_and_compose' "${COMPOSE}"
                ;;
            *)
                fatal "Invalid compose option."
                ;;
        esac
        exit
    fi
    if [[ -n ${ENVMETHOD-} ]]; then
        case "${ENVMETHOD-}" in
            --env)
                run_script_dialog "Creating environment variables for added apps." "Please be patient, this can take a while." "" \
                    'appvars_create_all'
                exit
                ;;
            --env-get)
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
            --env-get-lower)
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
            --env-get-line)
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
            --env-get-lower-line)
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
            --env-get-literal)
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
            --env-get-lower-literal)
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
            --env-set)
                if [[ ${ENVVAR-} != "" ]] && [[ ${ENVVAL-} != "" ]]; then
                    run_script 'env_backup'
                    run_script 'env_set' "${ENVVAR^^}" "${ENVVAL}"
                else
                    echo "Invalid usage. Must be"
                    echo "  --env-set with variable name and value ('--env-set=VAR,VAL' or '--env-set VAR=Val')"
                    echo "  Variable name will be forced to UPPER CASE"
                fi
                ;;
            --env-set-lower)
                if [[ ${ENVVAR-} != "" ]] && [[ ${ENVVAL-} != "" ]]; then
                    run_script 'env_backup'
                    run_script 'env_set' "${ENVVAR}" "${ENVVAL}"
                else
                    echo "Invalid usage. Must be"
                    echo "  --env-set-lower with variable name and value ('--env-set-lower=Var,VAL' or '--env-set-lower Var=Val')"
                    echo "  Variable name can be Mixed Case"
                fi
                ;;
            --env-appvars)
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
            --env-appvars-lines)
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
        run_script_dialog "Install DockSTARTer" "Install or update all DockSTARTer dependencies" "" \
            'run_install'
        exit
    fi
    if [[ -n ${LIST-} ]]; then
        run_script_dialog "List All Applications" "" "" \
            'app_list'
        exit
    fi
    if [[ -n ${LISTMETHOD-} ]]; then
        case "${LISTMETHOD-}" in
            --list-builtin)
                run_script_dialog "List Builtin Applications" "" "" \
                    'app_nicename' "$(run_script 'app_list_builtin')"
                ;;
            --list-depreciated)
                run_script_dialog "List Depreciated Applications" "" "" \
                    'app_nicename' "$(run_script 'app_list_depreciated')"
                ;;
            --list-nondepreciated)
                run_script_dialog "List Non-Depreciated Applications" "" "" \
                    'app_nicename' "$(run_script 'app_list_nondepreciated')"
                ;;
            --list-added)
                run_script_dialog "List Added Applications" "" "" \
                    'app_nicename' "$(run_script 'app_list_added')"
                ;;
            --list-enabled)
                run_script_dialog "List Enabled Applications" "" "" \
                    'app_nicename' "$(run_script 'app_list_enabled')"
                ;;
            --list-disabled)
                run_script_dialog "List Disabled Applications" "" "" \
                    'app_nicename' "$(run_script 'app_list_disabled')"
                ;;
            --list-referenced)
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
            run_script 'env_migrate_global'
            run_script 'appvars_purge_all'
            run_script 'env_update'
        else
            run_script 'env_migrate_global'
            run_script 'appvars_purge' "${REMOVE}"
            run_script 'env_update'
        fi
        exit
    fi
    if [[ -n ${STATUSMETHOD-} ]]; then
        case "${STATUSMETHOD-}" in
            --status)
                run_script_dialog "Application Status" "$(highlighted_list "$(run_script 'app_nicename' "${STATUS}")")" "" \
                    'app_status' "${STATUS}"
                ;;
            --status-enabled)
                run_script 'env_migrate_global'
                run_script 'enable_app' "${STATUS}"
                run_script 'env_update'
                ;;
            --status-disabled)
                run_script 'env_migrate_global'
                run_script 'disable_app' "${STATUS}"
                run_script 'env_update'
                ;;
            *)
                echo "Invalid option: '${STATUSMETHOD-}'"
                ;;
        esac
        exit
    fi

    if [[ -n ${TEST-} ]]; then
        run_test "${TEST}"
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
