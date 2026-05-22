#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=()

app_nicename_into() {
	# Return the "NiceName" of a single appname. If there is no "NiceName", return the "Title__Case" of "appname"
	local -n _ani_out_="${1}"
	assert_nameref_is_string "${1}"
	local _ani_AppName_="${2-}"
	_ani_AppName_="${_ani_AppName_%:*}"
	if ! run_script 'app_is_user_defined' "${_ani_AppName_}"; then
		run_script 'app_nicename_from_template_into' _ani_out_ "${_ani_AppName_}"
		return
	fi

	local -l _ani_baseapp_ _ani_instance_
	local _ani_BaseApp_ _ani_Instance_
	run_script 'appname_to_baseappname_into' _ani_baseapp_ "${_ani_AppName_}"
	_ani_BaseApp_="${_ani_baseapp_^}"
	run_script 'appname_to_instancename_into' _ani_instance_ "${_ani_AppName_}"
	_ani_Instance_=""
	if [[ -n ${_ani_instance_} ]]; then
		local _ani_cap_prefix_ _ani_cap_rest_
		_ani_cap_prefix_="${_ani_instance_%%[a-zA-Z]*}"
		_ani_cap_rest_="${_ani_instance_#"${_ani_cap_prefix_}"}"
		_ani_Instance_="__${_ani_cap_prefix_}${_ani_cap_rest_^}"
	fi
	_ani_out_="${_ani_BaseApp_}${_ani_Instance_}"
}

test_app_nicename_into() {
	local ForcePass='' # Force the tests to pass even on failure if set to a non-empty value
	local -i result=0
	run_script 'appvars_create' WATCHTOWER NZBGET
	local -a Test=(
		WATCHTOWER Watchtower
		SAMBA Samba
		RADARR Radarr
		nzbget NZBGet
		NZBGet NZBGet
		NZBGET NZBGet
		NONEXISTENTAPP Nonexistentapp
		WATCHTOWER__INSTANCE Watchtower__Instance
		SAMBA__INSTANCE Samba__Instance
		RADARR__INSTANCE Radarr__Instance
		NZBGET__INSTANCE Nzbget__Instance
		NONEXISTENTAPP__INSTANCE Nonexistentapp__Instance
		NONEXISTENTAPP__4K Nonexistentapp__4K
		NONEXISTENTAPP__23KKK Nonexistentapp__23Kkk
	)
	run_unit_tests_pipe "App" "App" "${ForcePass}" < <(
		for ((i = 0; i < ${#Test[@]}; i += 2)); do
			local Result
			run_script 'app_nicename_into' Result "${Test[i]}"
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
