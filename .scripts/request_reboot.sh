#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

request_reboot() {
    notice "Your system may need to reboot for changes to take effect."
    warn "If this is your first run reboot is required."
    warn "Failure to reboot on first run can cause errors with other operations."
    notice "Please run ${F[Y]}sudo reboot${NC} manually."
    notice "If this is not your first run you may disregard this message."
}

test_request_reboot() {
    run_script 'request_reboot'
}
