#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm__repos() {
    # Make sure a compatible package manager is available
    run_script 'package_manager_init'

    run_script "pm_${PM}_repos"
}

test_pm__repos() {
    run_script 'pm__repos'
}
