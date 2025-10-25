#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm__clean() {
    # Make sure a compatible package manager is available
    run_script 'package_manager_init'

    run_script "pm_${PM}_clean"
}

test_pm__clean() {
    run_script 'pm__clean'
}
