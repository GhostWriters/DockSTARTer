#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=(
	stat
)

declare Prefix="appvars_create_"

# shellcheck disable=SC2317  # Don't warn about unreachable commands in this function
needs_appvars_create() {
	return 0

	if [[ -n ${FORCE-} ]]; then
		return 0
	fi

	if [[ $# -eq 0 ]]; then
		local -a AppList
		readarray -t AppList < <(run_script 'app_list_added')
		if [[ -z ${AppList[*]-} ]]; then
			file_changed "${COMPOSE_ENV}"
			return
		fi
		run_script 'needs_appvars_create' "${AppList[@]}"
		return
	fi

	for AppName in "$@"; do
		local -u APPNAME=${AppName^^}
		if [[ -n ${APPNAME} ]]; then
			if file_changed "$(run_script 'app_env_file' "${APPNAME}")"; then
				# .env.app.env file has changed, return true
				return 0
			fi
			if ! file_changed "${COMPOSE_ENV}"; then
				# .env file has not changed, return false
				continue
			fi
			if ! run_script 'env_var_exists' "${APPNAME^^}__ENABLED"; then
				# No "enabled" variable for the app, return true
				return 0
			fi
		fi
	done
	return 1
}

file_changed() {
	local file=${1-}
	local timestamp_file
	timestamp_file="${TIMESTAMPS_FOLDER:?}/${Prefix}$(basename "${file}")"
	if [[ ! -f ${file} || ! -f ${timestamp_file} ]]; then
		return 0
	fi
	[[ $(${STAT} -c %Y "${file}") != $(${STAT} -c %Y "${timestamp_file}") ]]
}

test_needs_appvars_create() {
	warn "CI does not test needs_appvars_create."
}
