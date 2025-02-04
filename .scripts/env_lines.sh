#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

env_lines() {
    local VAR_FILE=${1:-$COMPOSE_ENV}
    sed -n "s/^\s*\([A-Za-z0-9_]*\)\s*=/\1=/p" "${VAR_FILE}" || true
}

test_env_lines() {
    run_script 'env_lines'
    #warn "CI does not test env_lines."
}
