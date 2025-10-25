#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_none_clean() {
    info "Package manager '${C["UserCommand"]}none${NC}' does not require cleanup."
}

test_pm_none_clean() {
    # run_script 'pm_none_clean'
    warn "CI does not test pm_none_clean."
}
