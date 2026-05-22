#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_is_disabled() {
	local -u APPNAME=${1-}
	if ! run_script 'app_is_builtin' "${APPNAME}"; then
		false
		return
	fi
	local _aid_enabled_
	run_script 'env_get_into' _aid_enabled_ "${APPNAME}__ENABLED"
	is_false "${_aid_enabled_}"
}

test_app_is_disabled() {
	run_script 'app_is_disabled' WATCHTOWER
	notice "'app_is_disabled' WATCHTOWER returned $?"
	run_script 'app_is_disabled' APPTHATDOESNOTEXIST
	notice "'app_is_disabled' APPTHATDOESNOTEXIST returned $?"
	#warn "CI does not test app_is_disabled."
}
