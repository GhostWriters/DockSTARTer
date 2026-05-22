#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=(
	grep
	sed
)

app_description_from_template_into() {
	# Return the description of a single appname.
	local -n _adft_out_="${1}"
	local _adft_appname_=${2-}
	_adft_appname_=${_adft_appname_,,}
	if run_script 'app_is_builtin' "${_adft_appname_}"; then
		local _adft_labels_yml_
		run_script 'app_instance_file_into' _adft_labels_yml_ "${_adft_appname_}" "*.labels.yml"
		if [[ -f ${_adft_labels_yml_} ]]; then
			_adft_out_="$(${GREP} --color=never -Po "\scom\.dockstarter\.appinfo\.description: \K.*" "${_adft_labels_yml_}" | ${SED} -E 's/^([^"].*[^"])$/"\1"/' | xargs || echo "! Missing description !")"
		else
			_adft_out_="! Missing application !"
		fi
	else
		local _adft_AppName_
		run_script 'app_nicename_into' _adft_AppName_ "${_adft_appname_}"
		_adft_out_="${_adft_AppName_} is a user defined application"
	fi
}

test_app_description_from_template_into() {
	local ForcePass='' # Force the tests to pass even on failure if set to a non-empty value
	local -i result=0
	run_script 'appvars_create' WATCHTOWER NZBGET
	local -a Test=(
		WATCHTOWER "Automatically update running Docker containers"
		SAMBA "(DEPRECATED) No replacement"
		RADARR "Automatically download movies via Usenet and BitTorrent"
		nzbget "Efficient usenet downloader"
		NZBGet "Efficient usenet downloader"
		NZBGET "Efficient usenet downloader"
		NONEXISTENTAPP "Nonexistentapp is a user defined application"
		WATCHTOWER__INSTANCE "Automatically update running Docker containers"
		SAMBA__INSTANCE "(DEPRECATED) No replacement"
		RADARR__INSTANCE "Automatically download movies via Usenet and BitTorrent"
		NZBGET__INSTANCE "Efficient usenet downloader"
		NONEXISTENTAPP__INSTANCE "Nonexistentapp__Instance is a user defined application"
	)
	run_unit_tests_pipe "App" "App" "${ForcePass}" < <(
		for ((i = 0; i < ${#Test[@]}; i += 2)); do
			local Result
			run_script 'app_description_from_template_into' Result "${Test[i]}"
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
