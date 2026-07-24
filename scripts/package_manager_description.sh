#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

package_manager_description() {
	local result
	run_script 'package_manager_description_into' result "${1-}"
	printf '%s\n' "${result}"
}

test_package_manager_description() {
	warn "CI does not test package_manager_description."
}
