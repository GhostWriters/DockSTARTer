#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=()

app_description_into() {
	# Return the description of a single appname.
	local -n _adi_out_="${1}"
	local -l _adi_appname_=${2-}
	_adi_appname_="${_adi_appname_%:*}"
	if run_script 'app_is_user_defined' "${_adi_appname_}"; then
		local _adi_AppName_
		run_script 'app_nicename_into' _adi_AppName_ "${_adi_appname_}"
		_adi_out_="${_adi_AppName_} is a user defined application"
	else
		run_script 'app_description_from_template_into' _adi_out_ "${_adi_appname_}"
	fi
}

test_app_description_into() {
	local ForcePass='' # Force the tests to pass even on failure if set to a non-empty value
	local -i result=0
	run_script 'appvars_create' WATCHTOWER NZBGET
	local -a Test=(
		WATCHTOWER "Automatically update running Docker containers"
		SAMBA "Samba is a user defined application"
		RADARR "Radarr is a user defined application"
		nzbget "Efficient usenet downloader"
		NZBGet "Efficient usenet downloader"
		NZBGET "Efficient usenet downloader"
		NONEXISTENTAPP "Nonexistentapp is a user defined application"
		WATCHTOWER__INSTANCE "Watchtower__Instance is a user defined application"
		SAMBA__INSTANCE "Samba__Instance is a user defined application"
		RADARR__INSTANCE "Radarr__Instance is a user defined application"
		NZBGET__INSTANCE "Nzbget__Instance is a user defined application"
		NONEXISTENTAPP__INSTANCE "Nonexistentapp__Instance is a user defined application"
	)
	run_unit_tests_pipe "App" "App" "${ForcePass}" < <(
		for ((i = 0; i < ${#Test[@]}; i += 2)); do
			local Result
			run_script 'app_description_into' Result "${Test[i]}"
			printf '%s\n' \
				"${Test[i]}" \
				"${Test[i + 1]}" \
				"${Result}"
		done
	)
	result=$?
	run_script 'appvars_purge' WATCHTOWER NZBGET
	return ${result}
}
