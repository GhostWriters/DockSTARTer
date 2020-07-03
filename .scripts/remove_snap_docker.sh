#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

remove_snap_docker() {
    if [[ -n "$(command -v snap)" ]]; then
        if snap services docker > /dev/null 2>&1; then
            info "Removing snap Docker package."
            snap remove docker > /dev/null 2>&1 || true
        fi
    fi
}

test_remove_snap_docker() {
    run_script 'remove_snap_docker'
}
