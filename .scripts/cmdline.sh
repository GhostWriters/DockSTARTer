#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

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
            --backup) LOCAL_ARGS="${LOCAL_ARGS:-}-b " ;;
            --compose) LOCAL_ARGS="${LOCAL_ARGS:-}-c " ;;
            --debug) LOCAL_ARGS="${LOCAL_ARGS:-}-x " ;;
            --env) LOCAL_ARGS="${LOCAL_ARGS:-}-e " ;;
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

    while getopts ":a:b:c:eghipr:t:u:vx" OPTION; do
        case ${OPTION} in
            a)
                run_script 'appvars_create' "${OPTARG}"
                run_script 'env_update'
                exit
                ;;
            b)
                case ${OPTARG} in
                    min)
                        run_script 'backup_min'
                        ;;
                    med)
                        run_script 'backup_med'
                        ;;
                    max)
                        run_script 'backup_max'
                        ;;
                    *)
                        fatal "Invalid backup option."
                        ;;
                esac
                exit
                ;;
            c)
                case ${OPTARG} in
                    down)
                        run_script 'run_compose' down
                        ;;
                    generate)
                        run_script 'generate_yml'
                        ;;
                    pull)
                        run_script 'generate_yml'
                        run_script 'run_compose' pull
                        ;;
                    restart)
                        run_script 'generate_yml'
                        run_script 'run_compose' restart
                        ;;
                    up)
                        run_script 'generate_yml'
                        run_script 'run_compose' up
                        ;;
                    *)
                        fatal "Invalid compose option."
                        ;;
                esac
                exit
                ;;
            e)
                run_script 'env_update'
                exit
                ;;
            h)
                usage
                exit
                ;;
            i)
                run_script 'run_install'
                exit
                ;;
            p)
                run_script 'prune_docker'
                exit
                ;;
            r)
                run_script 'appvars_purge' "${OPTARG}"
                run_script 'env_update'
                exit
                ;;
            t)
                run_test "${OPTARG}"
                exit
                ;;
            u)
                run_script 'update_self' "${OPTARG}"
                exit
                ;;
            v)
                readonly VERBOSE=1
                ;;
            x)
                readonly DEBUG='-x'
                set -x
                ;;
            :)
                case ${OPTARG} in
                    c)
                        run_script 'generate_yml'
                        run_script 'run_compose'
                        exit
                        ;;
                    r)
                        run_script 'appvars_purge_all'
                        exit
                        ;;
                    u)
                        run_script 'update_self'
                        exit
                        ;;
                    *)
                        fatal "${OPTARG} requires an option."
                        exit
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

test_cmdline() {
    # run_script 'cmdline'
    warning "Travis does not test cmdline."
}
