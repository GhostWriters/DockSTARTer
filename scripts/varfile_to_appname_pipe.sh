#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

varfile_to_appname_pipe() {
	# Returns the DS application name based on the variable filename passed to stdin
	local -a Args
	readarray -t Args < /dev/stdin
	if [[ -n ${Args[*]-} ]]; then
		run_script 'varfile_to_appname' "${Args[@]}"
	fi
}

test_varfile_to_appname_pipe() {
	local -a PathList=(
		'/home/test/.dockstarter/.env'
		'/home/test/.dockstarter/.env.app.radarr'
		'/home/test/.dockstarter/.env.app.Radarr'
		'/home/test/.dockstarter/.env.app.1radarr'
		'/home/test/.dockstarter/.env.app.radarr__4k'
		'/home/test/.dockstarter/.env.app.radarr___4k'
	)
	notice "$(run_script 'varfile_to_appname_pipe' < <(printf '%s\n' "${PathList[@]}"))"
}
