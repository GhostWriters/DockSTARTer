#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

package_manager_existing_list_into() {
	local -n _pmeli_out_="${1}"
	readarray -t _pmeli_out_ < <(run_script 'package_manager_existing_list')
}

test_package_manager_existing_list_into() {
	warn "CI does not test package_manager_existing_list_into."
}
