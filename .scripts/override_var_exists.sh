#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

override_var_exists() {
    local VarName=${1-}

    if [[ ! -f ${COMPOSE_OVERRIDE} ]]; then
        # No override file exists, return false
        return 1
    fi
    # Search for $VarName or ${VarName followed by a word break
    grep -P "\$\{?\K${VarName}\b" "${COMPOSE_OVERRIDE}"
}

test_override_var_exists() {
    warn "CI does not test override_var_exists."
}
