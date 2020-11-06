#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

pm_apt_repos() {
    info "Updating repositories."
    apt-get -y update > /dev/null 2>&1 || fatal "Failed to get updates from apt.\nFailing command: ${F[C]}apt-get -y update"
}

test_pm_apt_repos() {
    run_script 'pm_apt_repos'
}
