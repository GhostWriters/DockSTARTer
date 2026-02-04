#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=(
	column
)

app_list() {
	local -a AppList
	readarray -t AppList < <(run_script 'app_nicename' "$(run_script 'app_list_builtin')")
	local -a TableContents=(Application Deprecated Added Disabled)
	for AppName in "${AppList[@]}"; do
		local Deprecated=''
		local Added=''
		local Disabled=''
		if run_script 'app_is_deprecated' "${AppName}"; then
			Deprecated='[*DEPRECATED*]'
		fi
		if run_script 'app_is_added' "${AppName}"; then
			Added='*ADDED*'
			if run_script 'app_is_disabled' "${AppName}"; then
				Disabled='(Disabled)'
			fi
		fi
		TableContents+=("${AppName}" "${Deprecated}" "${Added}" "${Disabled}")
	done
	table 4 "${TableContents[@]-}"
}

test_app_list() {
	run_script 'env_create'
	run_script 'app_list'
	# warn "CI does not test app_list."
}
