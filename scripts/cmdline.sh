#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

cmdline() {
    # got this idea from here:
    # http://kirk.webfinish.com/2009/10/bash-shell-script-to-use-getopts-with-gnu-style-long-positional-parameters/
    local ARG=
    local LOCAL_ARGS
    for ARG; do
        local DELIM=""
        case "${ARG}" in
                #translate --gnu-long-options to -g (short options)
            --generate)       LOCAL_ARGS="${LOCAL_ARGS}-g " ;;
            --install)        LOCAL_ARGS="${LOCAL_ARGS}-i " ;;
            --test)           LOCAL_ARGS="${LOCAL_ARGS}-t " ;;
            --update)         LOCAL_ARGS="${LOCAL_ARGS}-u " ;;
            --verbose)        LOCAL_ARGS="${LOCAL_ARGS}-v " ;;
            --debug)          LOCAL_ARGS="${LOCAL_ARGS}-x " ;;
                #pass through anything else
            *) [[ "${ARG:0:1}" == "-" ]] || DELIM="\""
                LOCAL_ARGS="${LOCAL_ARGS:-}${DELIM}${ARG}${DELIM} " ;;
        esac
    done

    #Reset the positional parameters to the short options
    eval set -- "${LOCAL_ARGS:-}"

    while getopts "git:uvx" OPTION; do
        case ${OPTION} in
            g)
                run_script 'cmd_generate'
                exit 0
                ;;
            i)
                run_script 'cmd_install'
                exit 0
                ;;
            t)
                run_test "${OPTARG}"
                exit 0
                ;;
            u)
                run_script 'cmd_update'
                exit 0
                ;;
            v)
                readonly VERBOSE=1
                ;;
            x)
                readonly DEBUG='-x'
                set -x
                ;;
            *)
                usage
                exit 0
                ;;
        esac
    done
    return 0
}
