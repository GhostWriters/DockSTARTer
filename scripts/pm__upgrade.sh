#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm__upgrade() {
	# Make sure a compatible package manager is available
	run_script 'package_manager_init'

	run_script "pm_${PM}_upgrade"
}

test_pm__upgrade() {
	run_script 'pm__upgrade'
}
