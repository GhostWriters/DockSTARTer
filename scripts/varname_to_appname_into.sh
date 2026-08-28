#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

# Returns the DS application name based on the variable name passed --
# always the bare app[__instance] name, with any service/shared qualifier
# (see appname_strip_service_suffix_into) stripped. Use this for anything
# that looks up or groups by the app itself: template/nicename lookups,
# referenced-apps detection, etc. Use varname_to_appname_service_into
# instead when you specifically need to preserve the service qualifier
# (e.g. to strip an "APPNAME[__INST]___SERVICE__" prefix back off the same
# var name).
varname_to_appname_into() {
	local -n _vtai_out_="${1}"
	assert_nameref_is_string "${1}"
	local _vtai_Qualified_
	run_script 'varname_to_appname_service_into' _vtai_Qualified_ "${2-}"
	if [[ -n ${_vtai_Qualified_} ]]; then
		run_script 'appname_strip_service_suffix_into' _vtai_out_ "${_vtai_Qualified_}"
	else
		_vtai_out_=""
	fi
}

test_varname_to_appname_into() {
	local -a Tests=(
		SONARR_CONTAINER_NAME ""
		SONARR__CONTAINER_NAME "SONARR"
		SONARR__4K__CONTAINER_NAME "SONARR__4K"
		SONARR__4K__CONTAINER_NAME__TEST "SONARR__4K"
		SONARR__4K__CONTAINER__NAME "SONARR__4K"
		SONARR_4K__CONTAINER__NAME ""
		DOCKER_VOLUME_STORAGE ""
		# Colon-format (APPNAME:VARNAME) -- the colon prefix may itself
		# carry a service/shared qualifier identifying which .env.app.*
		# file it targets; stripped here too, same as the double-underscore
		# forms below.
		IMMICH-DATABASE:DB_HOSTNAME "IMMICH"
		# Multi-service scheme: APP[__INST]___SERVICE__VAR must resolve to
		# the app itself, with the service segment stripped -- this is the
		# bug class confirmed live on DockSTARTer2 (2026-08-28): a global
		# .env var's "IMMICH___ML__CONTAINER_NAME"-style name was being
		# compared unstripped against the plain "IMMICH" app name and
		# always failing validation, blocking Save.
		IMMICH___POSTGRES__CONTAINER_NAME "IMMICH"
		IMMICH__MYINSTANCE___POSTGRES__CONTAINER_NAME "IMMICH__MYINSTANCE"
		IMMICH__MYINSTANCE__CONTAINER_NAME "IMMICH__MYINSTANCE"
	)
	local -i result=0
	for ((i = 0; i < ${#Tests[@]}; i += 2)); do
		local Result
		run_script 'varname_to_appname_into' Result "${Tests[i]}"
		if [[ ${Result} != "${Tests[i + 1]}" ]]; then
			error "[${Tests[i]}]: expected [${Tests[i + 1]}] got [${Result}]"
			result=1
		else
			notice "[${Tests[i]}] = [${Result}]"
		fi
	done
	return ${result}
}
