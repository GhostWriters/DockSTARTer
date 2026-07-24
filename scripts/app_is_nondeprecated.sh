#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=()

app_is_nondeprecated() {
	local -l appname=${1-}
	local -l baseappname
	run_script 'appname_to_baseappname_into' baseappname "${appname}"
	local labels_yml
	run_script 'app_template_file_into' labels_yml "${baseappname}" "*.labels.yml"
	local APP_DEPRECATED=""
	if [[ -f ${labels_yml} ]]; then
		local line pattern='[[:space:]]com\.dockstarter\.appinfo\.deprecated: (.*)'
		while IFS= read -r line; do
			if [[ ${line} =~ ${pattern} ]]; then
				APP_DEPRECATED="${BASH_REMATCH[1]}"
				APP_DEPRECATED="${APP_DEPRECATED#\"}"
				APP_DEPRECATED="${APP_DEPRECATED%\"}"
				break
			fi
		done < "${labels_yml}"
	fi
	if [[ ${APP_DEPRECATED-} == "false" ]]; then
		return 0
	else
		return 1
	fi
}

test_app_is_nondeprecated() {
	run_script 'app_is_nondeprecated' WATCHTOWER
	notice "'app_is_nondeprecated' WATCHTOWER returned $?"
	run_script 'app_is_nondeprecated' SAMBA
	notice "'app_is_nondeprecated' SAMBA returned $?"
	run_script 'app_is_nondeprecated' APPTHATDOESNOTEXIST
	notice "'app_is_nondeprecated' APPTHATDOESNOTEXIST returned $?"
	#warn "CI does not test app_is_nondeprecated."
}
