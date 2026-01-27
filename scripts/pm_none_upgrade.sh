#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_none_upgrade() {
	info "Package manager '${C["UserCommand"]}none${NC}' does not require upgrades."
}

test_pm_none_upgrade() {
	# run_script 'pm_none_upgrade'
	warn "CI does not test pm_none_upgrade."
}
