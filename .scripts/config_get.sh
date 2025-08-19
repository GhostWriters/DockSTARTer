#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

config_get() {
    # config_get GET_VAR [VAR_FILE]
    local GET_VAR=${1-}
    local VAR_FILE=${2:-}

    if [[ -f ${VAR_FILE} ]]; then
        grep --color=never -Po "^\s*${GET_VAR}\s*=\K.*" "${VAR_FILE}" | tail -1 | xargs || true
    else
        # VAR_FILE does not exist, give a warning
        warn "File '${C["File"]}${VAR_FILE}${NC}' does not exist."
    fi

}

test_config_get() {
    warn "CI does not test config_get."
}
