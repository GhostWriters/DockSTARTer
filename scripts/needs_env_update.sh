#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=(
	stat
)

declare timestamps_folder="${TIMESTAMPS_FOLDER:?}/env_update"

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
		ReferencedAppsFile="${timestamps_folder:?}/${filename}_ReferencedApps"
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
		AppEnabledFile="${timestamps_folder:?}/${filename}_${APPNAME}__ENABLED"
		if ! cmp -s "${AppEnabledFile}" <(run_script 'env_get_line' "${APPNAME}__ENABLED" || true); then
			return 0
		fi
	fi
	return 1
}

file_changed() {
	local file=${1-}
	local timestamp_alias=${2-}
	local timestamp_file

	if [[ -n ${timestamp_alias} ]]; then
		timestamp_file="${timestamps_folder}/${timestamp_alias}"
	else
		timestamp_file="${timestamps_folder}/$(basename "${file}")"
	fi

	if [[ ! -f ${file} || ! -f ${timestamp_file} ]]; then
		# File or timestamp record is missing, return true (change detected)
		return 0
	fi

	if [[ $(${STAT} -c %Y "${file}") != $(${STAT} -c %Y "${timestamp_file}") ]]; then
		if cmp -s "${file}" "${timestamp_file}"; then
			# Contents are same, sync timestamp to avoid re-check and return false
			touch -r "${file}" "${timestamp_file}"
			return 1
		fi
		# Contents differ, return true
		return 0
	fi

	# No change detected, return false
	return 1
}

test_needs_env_update() {
	warn "CI does not test needs_env_update."
}
