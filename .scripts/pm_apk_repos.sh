#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_apk_repos() {
    info "apk does not require additional repositories."
}

test_pm_apk_repos() {
    # run_script 'pm_apk_repos'
    warn "CI does not test pm_apk_repos."
}
