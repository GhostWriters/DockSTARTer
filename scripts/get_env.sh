#!/bin/bash

get_env () {
    local VARS
    local ENV_VARS
    ENV_VARS=""
    if [[ -f ${SCRIPTPATH}/compose/.env ]]; then
        VARS="$(set -o posix; set)"
        source "${SCRIPTPATH}/compose/.env"
        ENV_VARS="$(grep -vFe "${VARS}" <<<"$(set -o posix; set)" | grep -v ^VARS=)"
        unset VARS
    fi
    echo "${ENV_VARS}"
}
