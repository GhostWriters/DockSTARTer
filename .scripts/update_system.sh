#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

update_system() {
    run_script 'package_manager_run' repos
    run_script 'package_manager_run' upgrade
    run_script 'package_manager_run' install
    run_script 'package_manager_run' clean
}

test_update_system() {
    run_script 'update_system'
}
