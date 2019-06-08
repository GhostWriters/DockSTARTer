#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

pm_apt_remove_python() {
    info "Removing conflicting Python packages."
    apt-get -y remove python-cryptography \
        python3-cryptography > /dev/null 2>&1 || true
}

test_pm_apt_remove_python() {
    run_script 'pm_apt_remove_python'
}
