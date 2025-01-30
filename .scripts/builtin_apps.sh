#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

builtin_apps() {
    find "${TEMPLATES_FOLDER}" -maxdepth 1 -mindepth 1 -type d -exec basename {} \; | sort || true
}

test_builtin_apps() {
    # run_script 'builtin_apps'
    warn "CI does not test builtin_apps."
}
