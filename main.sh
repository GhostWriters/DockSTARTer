#!/bin/bash

readonly SCRIPTNAME="$(basename "$0")"
readonly SCRIPTPATH="$(readlink -m "$(dirname "$0")")"
readonly ARGS="$*"

# # Colors
readonly CYAN='\e[34m'
readonly GREEN='\e[32m'
readonly RED='\e[31m'
readonly YELLOW='\e[33m'
readonly ENDCOLOR='\033[0m'

# # Check Arch
readonly ARCH=$(dpkg --print-architecture)

# # Check Systemd
if [[ -L "/sbin/init" ]]; then
    readonly ISSYSTEMD=true
else
    readonly ISSYSTEMD=false
fi

# # Github Token for Travis CI
if [[ ${CI} == true ]] && [[ ${TRAVIS} == true ]]; then
    readonly GH_HEADER="Authorization: token ${GH_TOKEN}"
fi

# # Usage Information
usage() {
    echo "Hello World"
}

# # Script Runner Function
run_script () {
    source "${SCRIPTPATH}/scripts/${1}.sh"
    ${1};
}

# # Test Runner Function
run_test () {
    source "${SCRIPTPATH}/test/${1}.sh"
    ${1};
}

# # Command Line Handler
cmdline() {
    # got this idea from here:
    # http://kirk.webfinish.com/2009/10/bash-shell-script-to-use-getopts-with-gnu-style-long-positional-parameters/
    local arg=
    for arg
    do
        local delim=""
        case "${arg}" in
                #translate --gnu-long-options to -g (short options)
            --generate)       args="${args}-g " ;;
            --install)        args="${args}-i " ;;
            --test)           args="${args}-t " ;;
            --verbose)        args="${args}-v " ;;
            --debug)          args="${args}-x " ;;
                #pass through anything else
            *) [[ "${arg:0:1}" == "-" ]] || delim="\""
                args="${args}${delim}${arg}${delim} " ;;
        esac
    done

    #Reset the positional parameters to the short options
    eval set -- "${args}"

    while getopts "git:vx" OPTION
    do
        case $OPTION in
            g)
                run_script 'generate_yml';
                run_script 'run_compose';
                exit 0
                ;;
            i)
                run_script 'root_check';
                run_script 'run_apt';
                run_script 'install_yq';
                run_script 'install_docker';
                run_script 'install_machine_completion';
                run_script 'install_compose';
                run_script 'install_compose_completion';
                run_script 'setup_docker_group';
                run_script 'enable_docker_systemd';
                run_script 'request_reboot';
                exit 0
                ;;
            t)
                run_test 'validate_newline' || exit 1;
                run_test 'validate_bashate' || exit 1;
                run_test 'validate_shellcheck' || exit 1;
                run_test 'run_install' || exit 1;
                run_test 'run_generate' || exit 1;
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

# # Main Function
main() {
    cmdline "${ARGS}"
}
main
