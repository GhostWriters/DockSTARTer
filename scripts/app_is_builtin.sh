#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_is_builtin() {
	local -l appname=${1-}

	local -l baseapp
	baseapp="$(run_script 'appname_to_baseappname' "${appname}")"
	[[ -d "${TEMPLATES_FOLDER}/${baseapp}" ]]
}

test_app_is_builtin() {
	local ForcePass='' # Force the tests to pass even on failure if set to a non-empty value
	local -i result=0
	local -a Test=(
		WATCHTOWER YES
		SAMBA YES
		RADARR YES
		nzbget YES
		NZBGet YES
		NZBGET YES
		NONEXISTENTAPP NO
		WATCHTOWER__INSTANCE YES
		SAMBA__INSTANCE YES
		RADARR__INSTANCE YES
		NZBGET__INSTANCE YES
		NONEXISTENTAPP__INSTANCE NO
	)
	run_unit_tests_pipe "App" "App" "${ForcePass}" < <(
		for ((i = 0; i < ${#Test[@]}; i += 2)); do
			printf '%s\n' \
				"${Test[i]}" \
				"${Test[i + 1]}" \
				"$(run_script 'app_is_builtin' "${Test[i]}" && echo "YES" || echo "NO")"
		done
	)
	result=$?
	return ${result}
}
