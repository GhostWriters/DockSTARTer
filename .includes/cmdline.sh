#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -gx PROMPT="CLI"

# Command Line Arguments
cmdline() {
    while getopts ":-:a:c:efghilpr:Rs:St:T:u:vV:x" OPTION; do
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
                    declare -gx ADD
                else
                    error "'${C["UserCommand"]-}${OPTION}${NC-}' requires an option."
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
                            declare -gx COMPOSE
                            ;;
                        *)
                            error "Invalid compose option '${C["UserCommand"]-}${OPTARG}${NC-}'."
                            exit 1
                            ;;
                    esac
                else
                    declare -gx COMPOSE=update
                fi
                ;;
            e | env)
                declare -gx ENVMETHOD='env'
                ;;
            env-appvars | env-appvars-lines)
                declare -gx ENVMETHOD=${OPTION}
                local MULTIOPT
                MULTIOPT=("$OPTARG")
                until [[ -z ${!OPTIND-} || ${!OPTIND} =~ ^-.* ]]; do
                    MULTIOPT+=("${!OPTIND}")
                    OPTIND=$((OPTIND + 1))
                done
                ENVAPP=$(printf "%s " "${MULTIOPT[@]}" | xargs)
                declare -gx ENVAPP
                ;;
            env-get=* | env-get-lower=* | env-get-line=* | env-get-lower-line=* | env-get-literal=* | env-get-lower-literal=*)
                declare -gx ENVMETHOD=${OPTION%%=*}
                declare -gx ENVARG=${OPTION#*=}
                if [[ ${ENVMETHOD-} != "${ENVARG-}" ]]; then
                    declare -gx ENVVAR=${ENVARG}
                fi
                ;;
            env-set=* | env-set-lower=*)
                declare -gx ENVMETHOD=${OPTION%%=*}
                declare -gx ENVARG=${OPTION#*=}
                if [[ ${ENVMETHOD-} != "${ENVARG-}" ]]; then
                    declare -gx ENVVAR=${ENVARG%%,*}
                    declare -gx ENVVAL=${ENVARG#*,}
                fi
                ;;
            env-get | env-get-lower | env-get-line | env-get-lower-line | env-get-literal | env-get-lower-literal)
                declare -gx ENVMETHOD=${OPTION}
                if [[ -z ${ENVVAR-} ]]; then
                    local MULTIOPT
                    MULTIOPT=("$OPTARG")
                    until [[ -z ${!OPTIND-} || ${!OPTIND} =~ ^-.* ]]; do
                        MULTIOPT+=("${!OPTIND}")
                        OPTIND=$((OPTIND + 1))
                    done
                    ENVVAR=$(printf "%s " "${MULTIOPT[@]}" | xargs)
                    declare -gx ENVVAR
                fi
                ;;
            env-set | env-set-lower)
                declare -gx ENVMETHOD=${OPTION}
                if [[ -z ${ENVVAR-} ]]; then
                    declare -gx ENVARG=${OPTARG}
                    declare -gx ENVVAR=${ENVARG%%=*}
                    declare -gx ENVVAL=${ENVARG#*=}
                fi
                ;;
            f | force)
                declare -gx FORCE=true
                ;;
            g | gui)
                if [[ -n ${DIALOG-} ]]; then
                    declare -gx PROMPT="GUI"
                else
                    warn "The '${C["UserCommand"]-}--gui${NC-}' option requires the '${C["Program"]-}dialog$}NC}' command to be installed."
                    warn "'${C["Program"]-}dialog${NC-}' command not found. Run '${C["UserCommand"]-}${APPLICATION_COMMAND} -fiv${NC-}' to install all dependencies."
                    warn "Coninuing without '${C["UserCommand"]-}--gui${NC-}' option."
                fi
                ;;
            h | help)
                usage
                exit
                ;;
            i | install)
                declare -gx INSTALL=true
                ;;
            l | list)
                declare -gx LISTMETHOD='list'
                declare -gx LIST=true
                ;;
            list-*)
                declare -gx LISTMETHOD=${OPTION}
                ;;
            p | prune)
                declare -gx PRUNE=true
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
                    declare -gx REMOVE
                else
                    error "'${C["UserCommand"]-}${OPTION}${NC-}' requires an option."
                    exit 1
                fi
                ;;
            R | reset)
                declare -gx RESET=1
                ;;
            status-*)
                if [[ -n ${OPTARG-} ]]; then
                    declare -gx STATUSMETHOD=${OPTION}
                    local MULTIOPT
                    MULTIOPT=("$OPTARG")
                    until [[ -z ${!OPTIND-} || ${!OPTIND} =~ ^-.* ]]; do
                        MULTIOPT+=("${!OPTIND}")
                        OPTIND=$((OPTIND + 1))
                    done
                    STATUS=$(printf "%s " "${MULTIOPT[@]}" | xargs)
                    declare -gx STATUS
                else
                    error "'${C["UserCommand"]-}${OPTION}${NC-}' requires an option."
                    exit 1
                fi
                ;;
            s | status)
                if [[ -n ${OPTARG-} ]]; then
                    declare -gx STATUSMETHOD='status'
                    local MULTIOPT
                    MULTIOPT=("$OPTARG")
                    until [[ -z ${!OPTIND-} || ${!OPTIND} =~ ^-.* ]]; do
                        MULTIOPT+=("${!OPTIND}")
                        OPTIND=$((OPTIND + 1))
                    done
                    STATUS=$(printf "%s " "${MULTIOPT[@]}" | xargs)
                    declare -gx STATUS
                else
                    error "'${C["UserCommand"]-}${OPTION}${NC-}' requires an option."
                    exit 1
                fi
                ;;
            S | select)
                declare -gx SELECT=1
                ;;
            t | test)
                if [[ -n ${OPTARG-} ]]; then
                    declare -gx TEST=${OPTARG}
                else
                    error "'${C["UserCommand"]-}${OPTION}${NC-}' requires an option."
                    exit 1
                fi
                ;;
            T | theme)
                declare -gx THEMEMETHOD='theme'
                if [[ -n ${OPTARG-} ]]; then
                    declare -gx THEME="${OPTARG}"
                    OPTIND=$((OPTIND + 1))
                fi
                ;;
            theme-*)
                declare -gx THEMEMETHOD=${OPTION}
                ;;
            u | update)
                UPDATE=true
                if [[ -n ${OPTARG-} ]]; then
                    UPDATE="${OPTARG}"
                fi
                declare -gx UPDATE
                ;;
            v | verbose)
                declare -gx VERBOSE=1
                ;;
            V | version)
                VERSION=''
                if [[ -n ${OPTARG-} && ${OPTARG:0:1} != '-' ]]; then
                    VERSION="${OPTARG}"
                fi
                declare -gx VERSION
                ;;
            x | debug)
                declare -gx DEBUG=1
                set -x
                ;;
            :)
                case ${OPTARG} in
                    c)
                        declare -gx COMPOSE=update
                        ;;
                    r)
                        declare -gx REMOVE=true
                        ;;
                    T)
                        declare -gx THEMEMETHOD='theme'
                        ;;
                    u)
                        declare -gx UPDATE=true
                        ;;
                    V)
                        declare -gx VERSION=''
                        ;;
                    *)
                        error "'${C["UserCommand"]-}${OPTARG}${NC-}' requires an option."
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
