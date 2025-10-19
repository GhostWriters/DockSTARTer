#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm__check_package_manager() {
    if [[ -n ${PM-} ]]; then
        return
    fi

    #shellcheck disable=SC2124 #Assigning an array to a string! Assign as array, or use * instead of @ to concatenate.
    local pmlist="${PM_PACKAGE_MANAGERS[@]}"
    pmlist="${pmlist// /${NC}\', \'${C["UserCommand"]}}"
    pmlist="${NC}'${C["UserCommand"]}${pmlist}${NC}'"
    fatal \
        "Unable to detect a compatible package manager. Compatible packages managers are:\n" \
        "   ${pmlist}"
}

test_pm__check_package_manager() {
    run_script 'pm__check_package_manager'
}
