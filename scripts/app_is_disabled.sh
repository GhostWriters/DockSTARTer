#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_is_disabled() {
	local -u APPNAME=${1-}
	# app_is_added requires __ENABLED to actually exist; app_is_builtin
	# alone wouldn't distinguish "explicitly false" from "not present."
	if ! run_script 'app_is_added' "${APPNAME}"; then
		false
		return
	fi
	local enabled
	run_script 'env_get_into' enabled "${APPNAME}__ENABLED"
	is_false "${enabled}"
}

test_app_is_disabled() {
	local ForcePass='' # Force the tests to pass even on failure if set to a non-empty value
	local -i result=0

	run_script 'app_is_disabled' WATCHTOWER
	notice "'app_is_disabled' WATCHTOWER returned $?"
	run_script 'app_is_disabled' APPTHATDOESNOTEXIST
	notice "'app_is_disabled' APPTHATDOESNOTEXIST returned $?"

	local -a NotAddedApps
	local NotAddedApp
	while IFS= read -r NotAddedApp; do
		if ! run_script 'app_is_added' "${NotAddedApp}"; then
			NotAddedApps+=("${NotAddedApp}")
		fi
	done < <(run_script 'app_list_builtin')
	if [[ ${#NotAddedApps[@]} -gt 0 ]]; then
		run_unit_tests_pipe "App" "App" "${ForcePass}" < <(
			printf '%s\n' \
				"${NotAddedApps[0]} (not added)" \
				"NO" \
				"$(run_script 'app_is_disabled' "${NotAddedApps[0]}" && echo "YES" || echo "NO")"
		)
		result=$?
	fi
	return ${result}
	#warn "CI does not test app_is_disabled."
}
