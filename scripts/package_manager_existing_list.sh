#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

package_manager_existing_list() {
	for PackageManager in "${PM_PACKAGE_MANAGERS[@]}"; do
		if run_script 'package_manager_exists' "${PackageManager}"; then
			printf '%s\n' "${PackageManager}"
		fi
	done
}

test_package_manager_existing_list() {
	run_script 'package_manager_existing_list'
}
