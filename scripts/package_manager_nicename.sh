#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

package_manager_nicename() {
	local result
	run_script 'package_manager_nicename_into' result "${1-}"
	printf '%s\n' "${result}"
}

test_package_manager_nicename() {
	warn "CI does not test package_manager_nicename."
}
