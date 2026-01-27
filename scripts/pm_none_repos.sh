#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_none_repos() {
	info "Package manager '${C["UserCommand"]}none${NC}' does not require additional repositories."
}

test_pm_none_repos() {
	# run_script 'pm_none_repos'
	warn "CI does not test pm_none_repos."
}
