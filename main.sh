#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Usage Information
#/ Usage: sudo ds [OPTION]
#/ NOTE: ds shortcut is only available after the first run of
#/       sudo bash main.sh
#/
#/ This is the main DockSTARTer script.
#/ For regular usage you can run without providing any options.
#/
#/  -a --add <appname>
#/      add the default .env variables for the app specified
#/  -c --compose
#/      run docker-compose up with confirmation prompt
#/  -c --compose <up/down/restart/pull>
#/      run docker-compose commands without confirmation prompts
#/  -e --env
#/      update your .env file with new variables
#/  --env-get=<var>
#/      get the value of a <var>iable in .env
#/  --env-set=<var>,<val>
#/      Set the <val>ue of a <var>iable in .env
#/  -f --force
#/      force certain install/upgrade actions to run even if they would not be needed
#/  -h --help
#/      show this usage information
#/  -i --install
#/      install/update docker, docker-compose, yq-go and all dependencies
#/  -p --prune
#/      remove unused docker resources
#/  -r --remove
#/      prompt to remove .env variables for all disabled apps
#/  -r --remove <appname>
#/      prompt to remove the .env variables for the app specified
#/  -t --test <test_name>
#/      run tests to check the program
#/  -u --update
#/      update DockSTARTer to the latest stable commits
#/  -u --update <branch>
#/      update DockSTARTer to the latest commits from the specified branch
#/  -v --verbose
#/      verbose
#/  --yml-get=<ymlvariable>
#/      Gets the value of a <ymlpath> for the app in the yml path (must start with 'services.<appname>.')
#/  --yml-get=<appname>,<ymlpath>
#/      Gets the value of a <ymlvariable> for the app specified
#/  -x --debug
#/      debug
#/
usage() {
    grep --color=never -Po '^#/\K.*' "${BASH_SOURCE[0]:-$0}" || echo "Failed to display usage information."
    exit
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
            --yml-*)
                readonly YMLMETHOD=${ARG%%=*}
                readonly YMLARG=${ARG#*=}
                if [[ ${YMLMETHOD:-} == "${YMLARG:-}" ]]; then
                    echo "Invalid usage. Must be one of the following:"
                    echo "  --yml-get with variable name '--yml-get=<ymlpath>' (must start with 'services.<appname>.')"
                    echo "  --yml-get with app name and variable name '--yml-get=<appname>,<ymlpath>'"
                    exit
                else
                    YMLAPPNAME=${YMLARG%%,*}
                    readonly YMLVAR=${YMLARG#*,}
                fi
                ;;
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
                        readonly COMPOSE=$(printf "%s " "${MULTIOPT[@]}" | xargs)
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

# Github Token for Travis CI
if [[ ${CI:-} == true ]] && [[ ${TRAVIS_SECURE_ENV_VARS:-} == true ]]; then
    readonly GH_HEADER="Authorization: token ${GH_TOKEN}"
    export GH_HEADER
fi

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
readonly SCRIPTPATH=$(cd -P "$(dirname "$(get_scriptname)")" > /dev/null 2>&1 && pwd)
readonly SCRIPTNAME="${SCRIPTPATH}/$(basename "$(get_scriptname)")"

# User/Group Information
readonly DETECTED_PUID=${SUDO_UID:-$UID}
readonly DETECTED_UNAME=$(id -un "${DETECTED_PUID}" 2> /dev/null || true)
readonly DETECTED_PGID=$(id -g "${DETECTED_PUID}" 2> /dev/null || true)
export DETECTED_PGID
readonly DETECTED_UGROUP=$(id -gn "${DETECTED_PUID}" 2> /dev/null || true)
export DETECTED_UGROUP
readonly DETECTED_HOMEDIR=$(eval echo "~${DETECTED_UNAME}" 2> /dev/null || true)

# Terminal Colors
if [[ ${CI:-} == true ]] || [[ -t 1 ]]; then
    readonly SCRIPTTERM=true
fi
tcolor() {
    if [[ -n ${SCRIPTTERM:-} ]]; then
        # http://linuxcommand.org/lc3_adv_tput.php
        local BF=${1:-}
        local CAP
        case ${BF} in
            [Bb]) CAP=setab ;;
            [Ff]) CAP=setaf ;;
            [Nn][Cc]) CAP=sgr0 ;;
            *) return ;;
        esac
        local COLOR_IN=${2:-}
        local VAL
        if [[ ${CAP} != "sgr0" ]]; then
            case ${COLOR_IN} in
                [Bb4]) VAL=4 ;; # Blue
                [Cc6]) VAL=6 ;; # Cyan
                [Gg2]) VAL=2 ;; # Green
                [Kk0]) VAL=0 ;; # Black
                [Mm5]) VAL=5 ;; # Magenta
                [Rr1]) VAL=1 ;; # Red
                [Ww7]) VAL=7 ;; # White
                [Yy3]) VAL=3 ;; # Yellow
                *) return ;;
            esac
        fi
        local COLOR_OUT
        if [[ $(tput colors 2> /dev/null) -ge 8 ]]; then
            COLOR_OUT=$(eval tput ${CAP:-} ${VAL:-} 2> /dev/null)
        fi
        echo "${COLOR_OUT:-}"
    else
        return
    fi
}
declare -Agr B=(
    [B]=$(tcolor B B)
    [C]=$(tcolor B C)
    [G]=$(tcolor B G)
    [K]=$(tcolor B K)
    [M]=$(tcolor B M)
    [R]=$(tcolor B R)
    [W]=$(tcolor B W)
    [Y]=$(tcolor B Y)
)
declare -Agr F=(
    [B]=$(tcolor F B)
    [C]=$(tcolor F C)
    [G]=$(tcolor F G)
    [K]=$(tcolor F K)
    [M]=$(tcolor F M)
    [R]=$(tcolor F R)
    [W]=$(tcolor F W)
    [Y]=$(tcolor F Y)
)
readonly NC=$(tcolor NC)

# Log Functions
readonly LOG_TEMP=$(mktemp) || echo "Failed to create temporary log file."
echo "DockSTARTer Log" > "${LOG_TEMP}"
log() {
    local TOTERM=${1:-}
    local MESSAGE=${2:-}
    echo -e "${MESSAGE:-}" | (
        if [[ -n ${TOTERM} ]]; then
            tee -a "${LOG_TEMP}" >&2
        else
            cat >> "${LOG_TEMP}" 2>&1
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
        ${SCRIPTSNAME} "$@"
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
            eval "test_${TESTSNAME}" "$@" || fatal "Failed to run ${TESTSNAME}."
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

# Cleanup Function
cleanup() {
    local -ri EXIT_CODE=$?

    if repo_exists; then
        info "Setting executable permission on ${SCRIPTNAME}"
        sudo -E chmod +x "${SCRIPTNAME}" > /dev/null 2>&1 || fatal "ds must be executable."
    fi
    if [[ ${CI:-} == true ]] && [[ ${TRAVIS_SECURE_ENV_VARS:-} == false ]]; then
        warn "TRAVIS_SECURE_ENV_VARS is false for Pull Requests from remote branches. Please retry failed builds!"
    fi

    if [[ ${EXIT_CODE} -ne 0 ]]; then
        error "DockSTARTer did not finish running successfully."
    fi

    sudo sh -c "cat ${LOG_TEMP} >> ${SCRIPTPATH}/dockstarter.log" || true

    exit ${EXIT_CODE}
    trap - 0 1 2 3 6 14 15
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
            git clone https://github.com/GunayAnach/DockSTARTer "${DETECTED_HOMEDIR}/.docker" || fatal "Failed to clone DockSTARTer repo to ${DETECTED_HOMEDIR}/.docker location."
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
    if [[ -n ${YMLMETHOD:-} ]]; then
        if [[ ${YMLAPPNAME:-} == "${YMLVAR:-}" ]]; then
            if [[ ${YMLVAR:-} != "" ]] && [[ ${YMLVAR:-} =~ services* ]]; then
                YMLAPPNAME=${YMLVAR#services.}
                YMLAPPNAME=${YMLAPPNAME%%.*}
            else
                YMLAPPNAME=""
            fi
        fi
        if [[ ${YMLAPPNAME:-} != "" ]] && [[ ${YMLVAR:-} != "" ]]; then
            run_script 'yml_get' "${YMLAPPNAME}" "${YMLVAR}" || error "Could not find '${YMLVAR}' in '${YMLAPPNAME}'"
        else
            echo "Invalid usage. Must be one of the following:"
            echo "  --yml-get with variable name '--yml-get=<ymlvar>' (must start with 'services.<appname>.')"
            echo "  --yml-get with app name and variable name '--yml-get=<appname>,<ymlvar>'"
        fi
        exit
    fi
    # Run Menus
    PROMPT="GUI"
    run_script 'menu_main'
}
main
