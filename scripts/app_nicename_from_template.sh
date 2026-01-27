#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=(
	grep
	sed
)

app_nicename_from_template() {
	# Return the "NiceName" of the appname(s) passed. If there is no "NiceName", return the "Title__Case" of "appname"
	local AppList
	AppList="$(xargs -n 1 <<< "$*")"
	for APPNAME in ${AppList}; do
		local AppName="${APPNAME%:*}"
		local -l baseapp instance
		local BaseApp Instance
		baseapp=$(run_script 'appname_to_baseappname' "${AppName}")
		BaseApp="${baseapp^}"
		labels_yml="$(run_script 'app_instance_file' "${baseapp}" "*.labels.yml")"
		if [[ -f ${labels_yml} ]]; then
			BaseApp="$(
				${GREP} --color=never -Po "\scom\.dockstarter\.appinfo\.nicename: \K.*" "${labels_yml}" | ${SED} -E 's/^([^"].*[^"])$/"\1"/' | xargs
			)"
		fi
		instance=$(run_script 'appname_to_instancename' "${AppName}")
		Instance=""
		if [[ -n ${instance} ]]; then
			Instance="__${instance^}"
		fi
		echo "${BaseApp}${Instance}"
	done
}

test_app_nicename_from_template() {
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
	)
	run_unit_tests_pipe "App" "App" "${ForcePass}" < <(
		for ((i = 0; i < ${#Test[@]}; i += 2)); do
			printf '%s\n' \
				"${Test[i]}" \
				"${Test[i + 1]}" \
				"$(run_script 'app_nicename_from_template' "${Test[i]}")"
		done
	)
	result=$?
	run_script 'appvars_purge' WATCHTOWER NZBGET
	return ${result}
}
