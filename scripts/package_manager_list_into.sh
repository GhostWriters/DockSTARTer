#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

package_manager_list_into() {
	local -n _pmli_out_="${1}"
	readarray -t _pmli_out_ < <(run_script 'package_manager_list')
}

test_package_manager_list_into() {
	warn "CI does not test package_manager_list_into."
}
