#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

pm_dnf_remove_python() {
    info "Removing conflicting Python packages."
    dnf -y remove python-cryptography \
        python3-cryptography > /dev/null 2>&1 || true
}

test_pm_dnf_remove_python() {
    # run_script 'pm_dnf_remove_python'
    warning "Travis does not test pm_dnf_remove_python."
}
