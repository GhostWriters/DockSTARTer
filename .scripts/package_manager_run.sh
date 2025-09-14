#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

package_manager_run() {
    local -l action=${1-}

    local -a PackageManagers=(
        apk
        apt
        dnf
        pacman
        yum
    )
    local -A PackageManagerCmd=(
        ["apk"]="apk"
        ["apt"]="apt-get"
        ["dnf"]="dnf"
        ["pacman"]="pacman"
        ["yum"]="yum"
    )
    local pm
    for pmname in "${PackageManagers[@]}"; do
        if [[ -n $(command -v "${PackageManagerCmd["${pmname}"]}") ]]; then
            pm="${pmname}"
            break
        fi
    done
    if [[ -z ${pm-} ]]; then
        #shellcheck disable=SC2124 #Assigning an array to a string! Assign as array, or use * instead of @ to concatenate.
        local pmlist="${PackageManagers[@]}"
        pmlist="${pmlist// /${NC}\', \'${C["UserCommand"]}}"
        pmlist="${NC}'${C["UserCommand"]}${pmlist}${NC}'"
        fatal "Unable to detect a compatible package manager. Compatible packages managers are:\n   ${pmlist}"
    fi

    run_script "pm_${pm}_${action}"

    if [[ ${action} == "install" ]]; then
        for CommandDep in "${COMMAND_DEPS[@]}"; do
            if [[ -z "$(command -v "${CommandDep}")" ]]; then
                fatal "'${C["Program"]}${CommandDep}${NC}' is not available. Please install '${C["Program"]}${CommandDep}${NC}' and try again."
            fi
        done
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
