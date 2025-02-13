#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

env_var_list() {
    local VAR_FILE=${1:-$COMPOSE_ENV}
    local VAR_REGEX="\w+"
    grep --color=never -o -P "^\s*\K${VAR_REGEX}(?=\s*=)" "${VAR_FILE}" || true
}

test_env_var_list() {
    run_script 'env_var_list'
}
