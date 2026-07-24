#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=()

app_nicename_from_template_into() {
	# Return the "NiceName" of a single appname. If there is no "NiceName", return the "Title__Case" of "appname"
	local -n _anft_out_="${1}"
	assert_nameref_is_string "${1}"
	local _anft_AppName_="${2-}"
	_anft_AppName_="${_anft_AppName_%:*}"
	local -l _anft_baseapp_ _anft_instance_
	local _anft_BaseApp_ _anft_Instance_ _anft_labels_yml_
	run_script 'appname_to_baseappname_into' _anft_baseapp_ "${_anft_AppName_}"
	_anft_BaseApp_="${_anft_baseapp_^}"
	run_script 'app_instance_file_into' _anft_labels_yml_ "${_anft_baseapp_}" "*.labels.yml"
	if [[ -f ${_anft_labels_yml_} ]]; then
		local _anft_line_ _anft_pattern_='[[:space:]]com\.dockstarter\.appinfo\.nicename: (.*)'
		while IFS= read -r _anft_line_; do
			if [[ ${_anft_line_} =~ ${_anft_pattern_} ]]; then
				local _anft_val_="${BASH_REMATCH[1]}"
				_anft_val_="${_anft_val_#\"}"
				_anft_val_="${_anft_val_%\"}"
				_anft_BaseApp_="${_anft_val_}"
				break
			fi
		done < "${_anft_labels_yml_}"
	fi
	run_script 'appname_to_instancename_into' _anft_instance_ "${_anft_AppName_}"
	_anft_Instance_=""
	if [[ -n ${_anft_instance_} ]]; then
		local _anft_cap_prefix_ _anft_cap_rest_
		_anft_cap_prefix_="${_anft_instance_%%[a-zA-Z]*}"
		_anft_cap_rest_="${_anft_instance_#"${_anft_cap_prefix_}"}"
		_anft_Instance_="__${_anft_cap_prefix_}${_anft_cap_rest_^}"
	fi
	_anft_out_="${_anft_BaseApp_}${_anft_Instance_}"
}

test_app_nicename_from_template_into() {
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
		NZBGET__INSTANCE NZBGet__Instance
		NONEXISTENTAPP__INSTANCE Nonexistentapp__Instance
		NONEXISTENTAPP__4K Nonexistentapp__4K
		NONEXISTENTAPP__23KKK Nonexistentapp__23Kkk
	)
	run_unit_tests_pipe "App" "App" "${ForcePass}" < <(
		for ((i = 0; i < ${#Test[@]}; i += 2)); do
			local Result
			run_script 'app_nicename_from_template_into' Result "${Test[i]}"
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
