#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

override_var_rename() {
    local FromVar=${1-}
    local ToVar=${2-}

    if [[ ! -f ${COMPOSE_OVERRIDE} ]]; then
        # No override file exists, do nothing
        return
    fi
    # Replace $FromVar or ${FromVar followed by a word break to $ToVar or ${ToVar
    sed -i -E "s/([$]\{?)${FromVar}\b/\1${ToVar}/g" "${COMPOSE_OVERRIDE}"
}

test_override_var_rename() {
    warn "CI does not test override_var_rename."
}
