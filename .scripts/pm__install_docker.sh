#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm__install_docker() {
    # Make sure a compatible package manager is available
    run_script 'pm__check_package_manager'

    run_script "pm_${PM}_install_docker"
}

test_pm__install_docker() {
    run_script 'pm__install_docker'
}
