#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=(
    sed
)

env_lines() {
    local VAR_FILE=${1:-$COMPOSE_ENV}
    if [[ -f ${VAR_FILE} ]]; then
        ${SED} -n "s/^\s*\([A-Za-z0-9_]*\)\s*=/\1=/p" "${VAR_FILE}"
    fi
}

test_env_lines() {
    run_script 'env_lines'
    #warn "CI does not test env_lines."
}
