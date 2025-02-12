#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

env_vars() {
    local VAR_FILE=${1:-$COMPOSE_ENV}
    local VAR_REGEX="\w+"
    grep --color=never -o -P "^\s*\K${VAR_REGEX}(?=\s*=)" "${VAR_FILE}" || true
}

test_env_vars() {
    run_script 'env_vars'
    #warn "CI does not test env_vars."
}
