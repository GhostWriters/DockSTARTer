#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

varfile_to_appname() {
	# Returns the DS application name based on the variable filename passed

	local VarFile=${1-}
	for VarFile in "$@"; do
		local AppName
		run_script 'varfile_to_appname_into' AppName "${VarFile}"
		if [[ -n ${AppName} ]]; then
			echo "${AppName}"
		fi
	done
}

test_varfile_to_appname() {
	local -a PathList=(
		'/home/test/.dockstarter/.env'
		'/home/test/.dockstarter/.env.app.radarr'
		'/home/test/.dockstarter/.env.app.Radarr'
		'/home/test/.dockstarter/.env.app.1radarr'
		'/home/test/.dockstarter/.env.app.radarr__4k'
		'/home/test/.dockstarter/.env.app.radarr___4k'
		'/home/test/.dockstarter/.env.app.radarr-4k'
	)
	for filepath in "${PathList[@]}"; do
		notice "[${filepath}] [$(run_script 'varfile_to_appname' "${filepath}")]"
	done
	notice "$(run_script 'varfile_to_appname' "${PathList[@]}")"
}
