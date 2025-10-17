#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

package_manager_run() {
    local -l action=${1-}

    if [[ -z ${PM-} ]]; then
        #shellcheck disable=SC2124 #Assigning an array to a string! Assign as array, or use * instead of @ to concatenate.
        local pmlist="${PM_PACKAGE_MANAGERS[@]}"
        pmlist="${pmlist// /${NC}\', \'${C["UserCommand"]}}"
        pmlist="${NC}'${C["UserCommand"]}${pmlist}${NC}'"
        fatal "Unable to detect a compatible package manager. Compatible packages managers are:\n   ${pmlist}"
    fi
    run_script "pm__${action}"

    case "${action}" in
        install)
            pm_check_dependencies fatal "${PM_COMMAND_DEPS[@]}"
            ;;
        install_docker)
            [[ -n "$(command -v docker)" ]] ||
                fatal "'${C["Program"]}docker${NC}' is not available. Please install '${C["Program"]}docker${NC}' and try again."
            docker compose version &> /dev/null ||
                fatal \
                    "Please see ${C["URL"]}https://docs.docker.com/compose/install/linux/${NC} to install '${C["Program"]}docker compose${NC}'\n" \
                    "'${C["Program"]}docker compose${NC}' is not available. Please install '${C["Program"]}docker compose${NC}' and try again."
            ;;
    esac
}

test_package_manager_run() {
    run_script 'package_manager_run' clean
}
