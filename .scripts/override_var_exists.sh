#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=(
    grep
)

override_var_exists() {
    local VarName=${1-}

    if [[ ! -f ${COMPOSE_OVERRIDE} ]]; then
        # No override file exists, return false
        return 1
    fi
    # Search for $VarName or ${VarName followed by a word break
    ${GREP} -q -P "[$]\{?${VarName}\b" "${COMPOSE_OVERRIDE}"
}

test_override_var_exists() {
    #warn "CI does not test override_var_exists."
    notice '[DOCKER_VOLUME_STORAGE]'
    run_script 'override_var_exists' DOCKER_VOLUME_STORAGE
    notice "Returned $?"
    notice '[NONEXISTENTVAR]'
    run_script 'override_var_exists' NONEXISTENTVAR
    notice "Returned $?"
}
