#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

request_reboot() {
    info "Your system may need to reboot for changes to take effect."
    info "Please run ${YLW}sudo reboot${NC} manually."
    warning "If this is your first run reboot is required."
    warning "Failure to reboot on first run can cause errors with other operations."
    info "If this is not your first run you may disregard this message."
}

test_request_reboot() {
    run_script 'request_reboot'
}
