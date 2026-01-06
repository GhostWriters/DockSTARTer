#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

package_manager_list() {
	printf '%s\n' "${PM_PACKAGE_MANAGERS[@]}"
}

test_package_manager_list() {
	run_script 'package_manager_list'
}
