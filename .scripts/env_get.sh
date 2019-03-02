#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

env_get() {
    local GET_VAR
    GET_VAR=${1:-}
    local VAR_VAL
    VAR_VAL=$(grep "^${GET_VAR}=" "${SCRIPTPATH}/compose/.env" | xargs || true)
    echo "${VAR_VAL#*=}"
}

test_env_get() {
    run_script 'env_get' DOCKERCONFDIR
}
