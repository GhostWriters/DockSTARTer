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
	local file1=${1-}
	local file2=${2-}
	local timestamp_file
	if [[ -n ${file2-} ]]; then
		# file2 is specified, use it for the timestamp
		timestamp_file="${timestamps_folder:?}/${file2}"
		if [[ ! -f ${file1} || ! -f ${timestamp_file} ]]; then
			# file1 or timestamp_file doesn't exist, return false
			return 0
		fi
		if [[ $(${STAT} -c %Y "${file1}") != $(${STAT} -c %Y "${timestamp_file}") ]]; then
			if cmp -s "${file1}" "${timestamp_file}"; then
				# Files are identical, update timestamp and return false
				touch -r "${file1}" "${timestamp_file}"
				return 1
			fi
			# Files are different, return true
			return 0
		fi
		return 1
	fi

	# file2 is not specified, use the file1 name for the timestamp
	timestamp_file="${timestamps_folder:?}/$(basename "${file1}")"
	if [[ ! -f ${file1} && ! -f ${timestamp_file} ]]; then
		# File doesn't exist and timestamp doesn't exist, return false
		return 1
	fi
	if [[ -f ${file1} && ! -f ${timestamp_file} ]]; then
		# File exists but timestamp doesn't, return true
		return 0
	fi
	if [[ ! -f ${file1} && -f ${timestamp_file} ]]; then
		# File doesn't exist but timestamp does, return true
		return 0
	fi
	# File exists and timestamp exists
	if [[ $(${STAT} -c %Y "${file1}") != $(${STAT} -c %Y "${timestamp_file}") ]]; then
		# Timestamp doesn't match file
		if cmp -s "${file1}" "${timestamp_file}"; then
			# Files are identical, update timestamp and return false
			touch -r "${file1}" "${timestamp_file}"
			return 1
		fi
		# Files are different, return true
		return 0
	fi
	# File hasn't changed
	if [[ ! -f ${timestamp_file} ]]; then
		# Timestamp doesn't exist, create it
		if [[ ! -d ${timestamps_folder} ]]; then
			# Timestamp folder doesn't exist, create it
			mkdir -p "${timestamps_folder}"
		fi
		cp -a "${file1}" "${timestamp_file}"
	else
		# Timestamp exists, update it
		touch -r "${file1}" "${timestamp_file}"
	fi
	return 1
}

test_needs_env_update() {
	warn "CI does not test needs_env_update."
}
