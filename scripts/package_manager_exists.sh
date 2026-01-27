#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

package_manager_exists() {
	local -l PackageManager=${1-}

	if [[ -z ${PackageManager-} ]]; then
		return 1
	fi
	if ! run_script 'package_manager_is_valid' "${PackageManager}"; then
		return 1
	fi
	if [[ -z $(command -v "${PM_PACKAGE_MANAGER_COMMAND["${PackageManager}"]-}") ]]; then
		return 1
	fi

	return 0
}

test_package_manager_exists() {
	local ForcePass='' # Force the tests to pass even on failure if set to a non-empty value
	local -i result=0
	local -a Test=(
		apt YES
		Apt YES
		nala NO
		Nala NO
		brew NO
		xxx NO
	)
	run_unit_tests_pipe "App" "App" "${ForcePass}" < <(
		for ((i = 0; i < ${#Test[@]}; i += 2)); do
			printf '%s\n' \
				"${Test[i]}" \
				"${Test[i + 1]}" \
				"$(run_script 'package_manager_exists' "${Test[i]}" && echo "YES" || echo "NO")"
		done
	)
	result=$?
	return ${result}
}
