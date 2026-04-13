#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_nicename() {
	# Return the "NiceName" of the appname(s) passed. If there is no "NiceName", return the "Title__Case" of "appname"
	local AppList
	AppList="$(xargs -n 1 <<< "$*")"
	for APPNAME in ${AppList}; do
		local AppName="${APPNAME%:*}"
		if ! run_script 'app_is_user_defined' "${AppName}"; then
			run_script 'app_nicename_from_template' "${AppName}"
			continue
		fi

		local -l baseapp instance
		local BaseApp Instance
		baseapp=$(run_script 'appname_to_baseappname' "${AppName}")
		BaseApp="${baseapp^}"
		instance=$(run_script 'appname_to_instancename' "${AppName}")
		Instance=""
		if [[ -n ${instance} ]]; then
			# Capitalize first letter character, skipping any leading digits.
			# e.g. "4k" → "4K", "instance" → "Instance"
			local cap_prefix cap_rest
			cap_prefix="${instance%%[a-zA-Z]*}"
			cap_rest="${instance#"${cap_prefix}"}"
			Instance="__${cap_prefix}${cap_rest^}"
		fi
		echo "${BaseApp}${Instance}"
	done

}

test_app_nicename() {
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
			printf '%s\n' \
				"${Test[i]}" \
				"${Test[i+1]}" \
				"$(run_script 'app_nicename' "${Test[i]}")"
		done
	)
	result=$?
	run_script 'appvars_purge' WATCHTOWER NZBGET
	return ${result}
}
