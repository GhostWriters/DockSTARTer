#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_is_enabled() {
	local -u APPNAME=${1-}
	if ! run_script 'app_is_builtin' "${APPNAME}"; then
		false
		return
	fi
	local _aie_enabled_
	run_script 'env_get_into' _aie_enabled_ "${APPNAME}__ENABLED"
	is_true "${_aie_enabled_}"
}

test_app_is_enabled() {
	run_script 'app_is_enabled' WATCHTOWER
	notice "'app_is_enabled' WATCHTOWER returned $?"
	run_script 'app_is_enabled' APPTHATDOESNOTEXIST
	notice "'app_is_enabled' APPTHATDOESNOTEXIST returned $?"
	#warn "CI does not test app_is_enabled."
}
