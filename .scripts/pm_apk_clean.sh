#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_apk_clean() {
    info "Package manager '${C["UserCommand"]}apk${NC}' does not require cleanup."
}

test_pm_apk_clean() {
    # run_script 'pm_apk_clean'
    warn "CI does not test pm_apk_clean."
}
