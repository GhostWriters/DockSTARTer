#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=(
	stat
)

declare Prefix="env_update_"

needs_env_update() {
	local VarFile=${1-}

	if [[ -n ${FORCE-} ]]; then
		return 0
	fi

	# Checking if we need to update .env
	if [[ ${VarFile} == "${COMPOSE_ENV}" ]]; then
		local filename
		filename="$(basename "${VarFile}")"
		local ReferencedAppsFile
		ReferencedAppsFile="$(timestamp_file "${filename}_ReferencedApps")"
		if file_changed "${VarFile}"; then
			return 0
		fi
		if [[ ! -f ${ReferencedAppsFile} ]] || ! cmp -s "${ReferencedAppsFile}" <(run_script 'app_list_referenced' || true); then
			return 0
		fi
		return 1
	fi

	# Checking if we need to update .env.app.appname
	if file_changed "${VarFile}"; then
		return 0
	fi
	local filename
	filename="$(basename "${VarFile}")"
	if file_changed "${COMPOSE_ENV}" "${filename}_$(basename "${COMPOSE_ENV}")"; then
		local -u APPNAME
		APPNAME="$(run_script 'varfile_to_appname' "${VarFile}")"
		local AppEnabledFile
		AppEnabledFile="$(timestamp_file "${filename}_${APPNAME}__ENABLED")"
		if ! cmp -s "${AppEnabledFile}" <(run_script 'env_get_line' "${APPNAME}__ENABLED" || true); then
			return 0
		fi
	fi
	return 1
}

timestamp_file() {
	printf "${TIMESTAMPS_FOLDER:?}/${Prefix}%s\n" "$1"
}

file_changed() {
	local file1=${1-}
	local file2=${2-}
	if [[ -z ${file2-} ]]; then
		file2="$(basename "${file1}")"
	fi
	file2="$(timestamp_file "${file2}")"
	if [[ ! -f ${file1} || ! -f ${file2} ]]; then
		return 0
	fi
	[[ $(${STAT} -c %Y "${file1}") != $(${STAT} -c %Y "${file2}") ]]
}

test_needs_env_update() {
	warn "CI does not test needs_env_update."
}
