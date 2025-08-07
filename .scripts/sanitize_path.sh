#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

sanitize_path() {
    local Value=${1-}
    if [[ ${Value} == *~* ]]; then
        # Value contains a "~", repace it with the user's home directory
        Value="${Value//\~/"${DETECTED_HOMEDIR}"}"
    fi
    echo "${Value}"
}
test_sanitize_path() {
    warn "CI does not test menu_app_select."
}
