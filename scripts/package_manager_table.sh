#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=(
	find
)

package_manager_table() {
	local -a TableArray=()
	local -a PackageManagerList
	run_script 'package_manager_list_into_array' PackageManagerList
	for PackageManagerName in "${PackageManagerList[@]-}"; do
		local PackageManagerDescription PackageManagerNicename
		run_script 'package_manager_description_into' PackageManagerDescription "${PackageManagerName}"
		run_script 'package_manager_nicename_into' PackageManagerNicename "${PackageManagerName}"
		TableArray+=("${PackageManagerName}" "${PackageManagerNicename}" "${PackageManagerDescription}")
	done
	table 3 "Package Manager" "Name" "Description" "${TableArray[@]}"
}

test_package_manager_table() {
	run_script 'package_manager_table'
}
