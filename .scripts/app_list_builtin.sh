#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=(
    find
)

app_list_builtin() {
    ${FIND} "${TEMPLATES_FOLDER}" -maxdepth 1 -mindepth 1 -type d -exec basename {} \; | tr '[:lower:]' '[:upper:]' | sort || true
}

test_app_list_builtin() {
    run_script 'app_list_builtin'
    # warn "CI does not test app_list_builtin."
}
