#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

theme_name() {
    run_script 'env_get' Theme "${MENU_INI_FILE}"
}

test_theme_name() {
    warn "CI does not test theme_name."
}
