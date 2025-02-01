#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

env_get() {
    local GET_VAR=${1-}
    local VAR_FILE=${2:-$COMPOSE_ENV}
    grep --color=never -Po "^\s*${GET_VAR}\s*=\K.*" "${VAR_FILE}" | tail -1 | xargs || true
}

test_env_get() {
    run_script 'env_get' DOCKER_VOLUME_CONFIG
}
