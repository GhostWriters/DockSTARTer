#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

apply_config() {
    if [[ ! -f ${APPLICATION_INI_FILE} ]]; then
        run_script 'config_create'
    fi
    run_script 'apply_theme'
    sort -o "${APPLICATION_INI_FILE}" "${APPLICATION_INI_FILE}"
}

test_apply_config() {
    warn "CI does not test apply_config."
}
