#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_zypper_clean() {
	info "Package manager '{{|UserCommand|}}zypper{{[-]}}' does not require cleanup."
}

test_pm_zypper_clean() {
	# run_script 'pm_zypper_clean'
	warn "CI does not test pm_zypper_clean."
}
