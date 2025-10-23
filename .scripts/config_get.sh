#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=(
    sed
)

config_get() {
    # config_get GET_VAR [VAR_FILE]
    local GET_VAR=${1-}
    local VAR_FILE=${2:-$APPLICATION_INI_FILE}

    if [[ -f ${VAR_FILE} ]]; then
        ${SED} -nE "s/^\s*${GET_VAR}\s*=\s*(.*)/\1/p" "${VAR_FILE}" | tail -1 | xargs || true
    else
        # VAR_FILE does not exist, give a warning
        warn "File '${C["File"]}${VAR_FILE}${NC}' does not exist."
    fi

}

test_config_get() {
    warn "CI does not test config_get."
}
