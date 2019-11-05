#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

pm_yum_remove_python_conflicts() {
    info "Removing conflicting Python packages."
    yum -y remove python-cryptography \
        python3-cryptography > /dev/null 2>&1 || true
}

test_pm_yum_remove_python_conflicts() {
    # run_script 'pm_yum_remove_python_conflicts'
    warn "CI does not test pm_yum_remove_python_conflicts."
}
