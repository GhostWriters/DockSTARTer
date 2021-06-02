#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

usage() {
    cat << EOF
Usage: ds [OPTION]
NOTE: ds shortcut is only available after the first run of
    bash main.sh

This is the main DockSTARTer script.
For regular usage you can run without providing any options.

-a --add <appname>
    add the default .env variables for the app specified
-c --compose
    run docker-compose up with confirmation prompt
-c --compose <up/down/restart/pull>
    run docker-compose commands without confirmation prompts
-e --env
    update your .env file with new variables
--env-get=<var>
    get the value of a <var>iable in .env
--env-set=<var>,<val>
    Set the <val>ue of a <var>iable in .env
-f --force
    force certain install/upgrade actions to run even if they would not be needed
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
    exit
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

# Cleanup Function
cleanup() {
    local -ri EXIT_CODE=$?
    sudo sh -c "cat ${MKTEMP_LOG:-/dev/null} >> ${SCRIPTPATH}/dockstarter.log" || true
    sudo rm -f "${MKTEMP_LOG}" || true
    sudo sh -c "echo \"$(tail -1000 "${SCRIPTPATH}/dockstarter.log")\" > ${SCRIPTPATH}/dockstarter.log" || true
    sudo -E chmod +x "${SCRIPTNAME}" > /dev/null 2>&1 || true

    if [[ ${CI:-} == true ]] && [[ ${TRAVIS_SECURE_ENV_VARS:-} == false ]]; then
        echo "TRAVIS_SECURE_ENV_VARS is false for Pull Requests from remote branches. Please retry failed builds!"
    fi

    if [[ ${EXIT_CODE} -ne 0 ]]; then
        echo "DockSTARTer did not finish running successfully."
    fi

    exit ${EXIT_CODE}
    trap - ERR EXIT SIGABRT SIGALRM SIGHUP SIGINT SIGQUIT SIGTERM
}
trap 'cleanup' ERR EXIT SIGABRT SIGALRM SIGHUP SIGINT SIGQUIT SIGTERM

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
            --add) LOCAL_ARGS="${LOCAL_ARGS:-}-a " ;;
            --compose) LOCAL_ARGS="${LOCAL_ARGS:-}-c " ;;
            --debug) LOCAL_ARGS="${LOCAL_ARGS:-}-x " ;;
            --env) LOCAL_ARGS="${LOCAL_ARGS:-}-e " ;;
            --env-*)
                readonly ENVMETHOD=${ARG%%=*}
                readonly ENVARG=${ARG#*=}
                if [[ ${ENVMETHOD:-} == "${ENVARG:-}" ]]; then
                    echo "Invalid usage. Must be on of the following:"
                    echo "  --env-set with variable name ('--env-set=VAR,VAL') and value"
                    echo "  --env-get with variable name ('--env-get=VAR')"
                    exit
                else
                    readonly ENVVAR=${ENVARG%%,*}
                    readonly ENVVAL=${ENVARG#*,}
                fi
                ;;
            --force) LOCAL_ARGS="${LOCAL_ARGS:-}-f " ;;
            --help) LOCAL_ARGS="${LOCAL_ARGS:-}-h " ;;
            --install) LOCAL_ARGS="${LOCAL_ARGS:-}-i " ;;
            --prune) LOCAL_ARGS="${LOCAL_ARGS:-}-p " ;;
            --remove) LOCAL_ARGS="${LOCAL_ARGS:-}-r " ;;
            --test) LOCAL_ARGS="${LOCAL_ARGS:-}-t " ;;
            --update) LOCAL_ARGS="${LOCAL_ARGS:-}-u " ;;
            --verbose) LOCAL_ARGS="${LOCAL_ARGS:-}-v " ;;
            #pass through anything else
            *)
                [[ ${ARG:0:1} == "-" ]] || DELIM='"'
                LOCAL_ARGS="${LOCAL_ARGS:-}${DELIM}${ARG}${DELIM} "
                ;;
        esac
    done

    #Reset the positional parameters to the short options
    eval set -- "${LOCAL_ARGS:-}"

    while getopts ":a:c:efghipr:t:u:vx" OPTION; do
        case ${OPTION} in
            a)
                readonly ADD=${OPTARG}
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
                readonly ENV=true
                ;;
            f)
                readonly FORCE=true
                ;;
            h)
                usage
                exit
                ;;
            i)
                readonly INSTALL=true
                ;;
            p)
                readonly PRUNE=true
                ;;
            r)
                readonly REMOVE=${OPTARG}
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
cmdline "${ARGS[@]:-}"
if [[ -n ${DEBUG:-} ]] && [[ -n ${VERBOSE:-} ]]; then
    readonly TRACE=1
fi

# Terminal Colors
declare -Agr B=(# Background
    [B]=$(tput setab 4 2> /dev/null || echo -e "\e[44m") # Blue
    [C]=$(tput setab 6 2> /dev/null || echo -e "\e[46m") # Cyan
    [G]=$(tput setab 2 2> /dev/null || echo -e "\e[42m") # Green
    [K]=$(tput setab 0 2> /dev/null || echo -e "\e[40m") # Black
    [M]=$(tput setab 5 2> /dev/null || echo -e "\e[45m") # Magenta
    [R]=$(tput setab 1 2> /dev/null || echo -e "\e[41m") # Red
    [W]=$(tput setab 7 2> /dev/null || echo -e "\e[47m") # White
    [Y]=$(tput setab 3 2> /dev/null || echo -e "\e[43m") # Yellow
)
declare -Agr F=(# Foreground
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

# Log Functions
MKTEMP_LOG=$(mktemp) || echo "Failed to create temporary log file."
readonly MKTEMP_LOG
echo "DockSTARTer Log" > "${MKTEMP_LOG}"
log() {
    local TOTERM=${1:-}
    local MESSAGE=${2:-}
    echo -e "${MESSAGE:-}" | (
        if [[ -n ${TOTERM} ]]; then
            tee -a "${MKTEMP_LOG}" >&2
        else
            cat >> "${MKTEMP_LOG}" 2>&1
        fi
    )
}
trace() { log "${TRACE:-}" "${NC}$(date +"%F %T") ${F[B]}[TRACE ]${NC}   $*${NC}"; }
debug() { log "${DEBUG:-}" "${NC}$(date +"%F %T") ${F[B]}[DEBUG ]${NC}   $*${NC}"; }
info() { log "${VERBOSE:-}" "${NC}$(date +"%F %T") ${F[B]}[INFO  ]${NC}   $*${NC}"; }
notice() { log "true" "${NC}$(date +"%F %T") ${F[G]}[NOTICE]${NC}   $*${NC}"; }
warn() { log "true" "${NC}$(date +"%F %T") ${F[Y]}[WARN  ]${NC}   $*${NC}"; }
error() { log "true" "${NC}$(date +"%F %T") ${F[R]}[ERROR ]${NC}   $*${NC}"; }
fatal() {
    log "true" "${NC}$(date +"%F %T") ${B[R]}${F[W]}[FATAL ]${NC}   $*${NC}"
    exit 1
}

# User/Group Information
readonly DETECTED_PUID=${SUDO_UID:-$UID}
DETECTED_UNAME=$(id -un "${DETECTED_PUID}" 2> /dev/null || true)
readonly DETECTED_UNAME
DETECTED_PGID=$(id -g "${DETECTED_PUID}" 2> /dev/null || true)
readonly DETECTED_PGID
export DETECTED_PGID
DETECTED_UGROUP=$(id -gn "${DETECTED_PUID}" 2> /dev/null || true)
readonly DETECTED_UGROUP
export DETECTED_UGROUP
DETECTED_HOMEDIR=$(eval echo "~${DETECTED_UNAME}" 2> /dev/null || true)
readonly DETECTED_HOMEDIR

# Repo Exists Function
repo_exists() {
    if [[ -d ${SCRIPTPATH}/.git ]] && [[ -d ${SCRIPTPATH}/.scripts ]]; then
        return
    else
        return 1
    fi
}

# Root Check Function
root_check() {
    if [[ ${DETECTED_PUID} == "0" ]] || [[ ${DETECTED_HOMEDIR} == "/root" ]]; then
        fatal "Running as root is not supported. Please run as a standard user with sudo."
    fi
}

# Script Runner Function
run_script() {
    local SCRIPTSNAME=${1:-}
    shift
    if [[ -f ${SCRIPTPATH}/.scripts/${SCRIPTSNAME}.sh ]]; then
        # shellcheck source=/dev/null
        source "${SCRIPTPATH}/.scripts/${SCRIPTSNAME}.sh"
        ${SCRIPTSNAME} "$@" < /dev/null
    else
        fatal "${SCRIPTPATH}/.scripts/${SCRIPTSNAME}.sh not found."
    fi
}

# Test Runner Function
run_test() {
    local TESTSNAME=${1:-}
    shift
    if [[ -f ${SCRIPTPATH}/.scripts/${TESTSNAME}.sh ]]; then
        if grep -q "test_${TESTSNAME}" "${SCRIPTPATH}/.scripts/${TESTSNAME}.sh"; then
            notice "Testing ${TESTSNAME}."
            # shellcheck source=/dev/null
            source "${SCRIPTPATH}/.scripts/${TESTSNAME}.sh"
            eval "test_${TESTSNAME}" "$@" < /dev/null || fatal "Failed to run ${TESTSNAME}."
            notice "Completed testing ${TESTSNAME}."
        else
            fatal "Test function in ${SCRIPTPATH}/.scripts/${TESTSNAME}.sh not found."
        fi
    else
        fatal "${SCRIPTPATH}/.scripts/${TESTSNAME}.sh not found."
    fi
}

# Version Functions
# https://stackoverflow.com/questions/4023830/how-to-compare-two-strings-in-dot-separated-version-format-in-bash#comment92693604_4024263
vergte() { printf '%s\n%s' "${2}" "${1}" | sort -C -V; }
vergt() { ! vergte "${2}" "${1}"; }
verlte() { printf '%s\n%s' "${1}" "${2}" | sort -C -V; }
verlt() { ! verlte "${2}" "${1}"; }

# Github Token for CI
if [[ ${CI:-} == true ]] && [[ ${TRAVIS_SECURE_ENV_VARS:-} == true ]]; then
    readonly GH_HEADER="Authorization: token ${GH_TOKEN}"
    export GH_HEADER
fi

# Main Function
main() {
    # Arch Check
    ARCH=$(uname -m)
    readonly ARCH
    if [[ ${ARCH} != "aarch64" ]] && [[ ${ARCH} != "armv7l" ]] && [[ ${ARCH} != "x86_64" ]]; then
        fatal "Unsupported architecture."
    fi
    # Terminal Check
    if [[ -t 1 ]]; then
        root_check
    fi
    # Repo Check
    local PROMPT
    if [[ ${FORCE:-} == true ]]; then
        PROMPT="FORCE"
    fi
    local DS_COMMAND
    DS_COMMAND=$(command -v ds || true)
    if [[ -L ${DS_COMMAND} ]]; then
        local DS_SYMLINK
        DS_SYMLINK=$(readlink -f "${DS_COMMAND}")
        if [[ ${SCRIPTNAME} != "${DS_SYMLINK}" ]]; then
            if repo_exists; then
                if run_script 'question_prompt' "${PROMPT:-CLI}" N "DockSTARTer installation found at ${DS_SYMLINK} location. Would you like to run ${SCRIPTNAME} instead?"; then
                    run_script 'symlink_ds'
                    DS_COMMAND=$(command -v ds || true)
                    DS_SYMLINK=$(readlink -f "${DS_COMMAND}")
                fi
            fi
            warn "Attempting to run DockSTARTer from ${DS_SYMLINK} location."
            sudo -E bash "${DS_SYMLINK}" -vu
            sudo -E bash "${DS_SYMLINK}" -vi
            exec sudo -E bash "${DS_SYMLINK}" "${ARGS[@]:-}"
        fi
    else
        if ! repo_exists; then
            warn "Attempting to clone DockSTARTer repo to ${DETECTED_HOMEDIR}/.docker location."
            # Anti Sudo Check
            if [[ ${EUID} -eq 0 ]]; then
                fatal "Using sudo during cloning on first run is not supported."
            fi
            git clone https://github.com/GhostWriters/DockSTARTer "${DETECTED_HOMEDIR}/.docker" || fatal "Failed to clone DockSTARTer repo.\nFailing command: ${F[C]}git clone https://github.com/GhostWriters/DockSTARTer \"${DETECTED_HOMEDIR}/.docker\""
            notice "Performing first run install."
            exec sudo -E bash "${DETECTED_HOMEDIR}/.docker/main.sh" "-vi"
        fi
    fi
    # Sudo Check
    if [[ ${EUID} -ne 0 ]]; then
        exec sudo -E bash "${SCRIPTNAME}" "${ARGS[@]:-}"
    fi
    # Create Symlink
    run_script 'symlink_ds'
    # Execute CLI Argument Functions
    if [[ -n ${ADD:-} ]]; then
        run_script 'appvars_create' "${ADD}"
        run_script 'env_update'
        exit
    fi
    if [[ -n ${COMPOSE:-} ]]; then
        case ${COMPOSE} in
            down)
                run_script 'docker_compose' "${COMPOSE}"
                ;;
            generate | merge)
                run_script 'yml_merge'
                ;;
            pull* | restart* | up*)
                run_script 'yml_merge'
                run_script 'docker_compose' "${COMPOSE}"
                ;;
            *)
                fatal "Invalid compose option."
                ;;
        esac
        exit
    fi
    if [[ -n ${ENV:-} ]]; then
        run_script 'env_update'
        run_script 'appvars_create_all'
        exit
    fi
    if [[ -n ${ENVMETHOD:-} ]]; then
        case "${ENVMETHOD:-}" in
            --env-get)
                if [[ ${ENVVAR:-} != "" ]]; then
                    run_script 'env_get' "${ENVVAR}"
                else
                    echo "Invalid usage. Must be"
                    echo "  --env-get with variable name ('--env-get=VAR')"
                fi
                ;;
            --env-set)
                if [[ ${ENVVAR:-} != "" ]] && [[ ${ENVVAL:-} != "" ]]; then
                    run_script 'env_set' "${ENVVAR}" "${ENVVAL}"
                else
                    echo "Invalid usage. Must be"
                    echo "  --env-set with variable name and value ('--env-set=VAR,VAL')"
                fi
                ;;
            *)
                echo "Invalid option: '${ENVMETHOD:-}'"
                ;;
        esac
        exit
    fi
    if [[ -n ${INSTALL:-} ]]; then
        run_script 'run_install'
        exit
    fi
    if [[ -n ${PRUNE:-} ]]; then
        run_script 'docker_prune'
        exit
    fi
    if [[ -n ${REMOVE:-} ]]; then
        if [[ ${REMOVE} == true ]]; then
            run_script 'appvars_purge_all'
            run_script 'env_update'
        else
            run_script 'appvars_purge' "${REMOVE}"
            run_script 'env_update'
        fi
        exit
    fi
    if [[ -n ${TEST:-} ]]; then
        run_test "${TEST}"
        exit
    fi
    if [[ -n ${UPDATE:-} ]]; then
        if [[ ${UPDATE} == true ]]; then
            run_script 'update_self'
        else
            run_script 'update_self' "${UPDATE}"
        fi
        exit
    fi
    # Run Menus
    PROMPT="GUI"
    run_script 'menu_main'
}
main
