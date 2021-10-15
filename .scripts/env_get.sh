#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

env_get() {
    local GET_VAR=${1:-}
    local VAR_FILE=${2:-$SCRIPTPATH/compose/.env}
    eval "${GET_VAR}=\"\""
    eval "$(grep --color=never -E "^${GET_VAR}=.*" "${VAR_FILE}" || true)"
    echo "${!GET_VAR}" || true
}

test_env_get() {
    run_script 'env_get' DOCKERCONFDIR
}
