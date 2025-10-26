#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm__install() {
    # Make sure a compatible package manager is available
    run_script 'package_manager_init'

    # Determine the dependencies needing to be installed
    local -a Dependencies=("${PM_COMMAND_DEPS[@]}")
    if [[ ${FORCE-} != true ]]; then
        for index in "${!Dependencies[@]}"; do
            if pm_check_dependency "${Dependencies[index]}"; then
                unset 'Dependencies[index]'
            fi
        done
    fi

    # Exit if no dependencies need to be installed
    if [[ ${#Dependencies[@]} -eq 0 ]]; then
        notice "All dependencies have already been installed."
        return
    fi

    #shellcheck disable=SC2124 #Assigning an array to a string! Assign as array, or use * instead of @ to concatenate.
    local deplist="${Dependencies[@]}"
    deplist="${deplist// /${NC}\', \'${C["Program"]}}"
    deplist="${NC}'${C["Program"]}${deplist}${NC}'"

    # Install missing dependencies using the package manager
    notice "Installing dependencies: ${deplist}"
    run_script "pm_${PM}_install" "${Dependencies[@]}"
}

test_pm__install() {
    run_script 'pm__install'
}
