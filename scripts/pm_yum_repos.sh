#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_yum_repos() {
	info "Package manager '{{|UserCommand|}}yum{{[-]}}' does not require additional repositories."
}

test_pm_yum_repos() {
	# run_script 'pm_yum_repos'
	warn "CI does not test pm_yum_repos."
}
