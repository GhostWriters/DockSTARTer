#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=()

app_description_from_template() {
	local result
	run_script 'app_description_from_template_into' result "$@"
	echo "${result}"
}

test_app_description_from_template() {
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
			printf '%s\n' \
				"${Test[i]}" \
				"${Test[i + 1]}" \
				"$(run_script 'app_description_from_template' "${Test[i]}")"
		done
	)
	result=$?
	run_script 'appvars_purge' WATCHTOWER NZBGET
	return ${result}
}
