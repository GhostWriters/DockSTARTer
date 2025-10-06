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
    run_script "pm_${PM}_${action}"

    if [[ ${action} == "install" ]]; then
        local failed=''
        for Dep in "${PM_COMMAND_DEPS[@]}"; do
            if ! pm_check_dependency "${Dep}"; then
                error "'${C["Program"]}${Dep}${NC}' is not available. Please install '${C["Program"]}${Dep}${NC}' and try again."
                failed="true"
            fi
        done
        if [[ -n ${failed} ]]; then
            fatal "Dependencies not installed."
        fi
    elif [[ ${action} == "install_docker" ]]; then
        if [[ -z "$(command -v docker)" ]]; then
            fatal "'${C["Program"]}docker${NC}' is not available. Please install '${C["Program"]}docker${NC}' and try again."
        fi
        if ! docker compose version > /dev/null 2>&1; then
            warn "Please see ${C["URL"]}https://docs.docker.com/compose/install/linux/${NC} to install '${C["Program"]}docker compose${NC}'"
            fatal "'${C["Program"]}docker compose${NC}' is not available. Please install '${C["Program"]}docker compose${NC}' and try again."
        fi
    fi
}

test_package_manager_run() {
    run_script 'package_manager_run' clean
}
