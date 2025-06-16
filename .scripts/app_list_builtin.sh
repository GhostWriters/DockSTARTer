#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_list_builtin() {
    find "${TEMPLATES_FOLDER}" -maxdepth 1 -mindepth 1 -type d -exec basename {} \; | tr '[:lower:]' '[:upper:]' | sort || true
}

test_app_list_builtin() {
    run_script 'app_list_builtin'
    # warn "CI does not test app_list_builtin."
}
