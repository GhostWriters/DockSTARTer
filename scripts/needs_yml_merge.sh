#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=(
	stat
)

declare timestamps_folder="${TIMESTAMPS_FOLDER:?}/yml_merge"

needs_yml_merge() {
	if [[ -n ${FORCE-} ]]; then
		return 0
	fi

	if [[ ! -f ${DOCKER_COMPOSE_FILE} ]]; then
		# Compose file doesn't exists, return true
		return 0
	fi

	if file_changed "${DOCKER_COMPOSE_FILE}"; then
		# Compose file has changed, return true
		return 0
	fi
	if file_changed "${COMPOSE_ENV}"; then
		# .env has changed, return true
		return 0
	fi
	for AppName in $(run_script 'app_list_enabled'); do
		if file_changed "$(run_script 'app_env_file' "${AppName}")"; then
			# .env.app.appname has changed, return true
			return 0
		fi
	done

	# No files have changed, return false
	return 1
}

file_changed() {
	local file=${1}
	local timestamp_file
	timestamp_file="${timestamps_folder:?}/$(basename "${file}")"
	if [[ ! -f ${file} && ! -f ${timestamp_file} ]]; then
		# File doesn't exist and timestamp doesn't exist, return false
		return 1
	fi
	if [[ -f ${file} && ! -f ${timestamp_file} ]]; then
		# File exists but timestamp doesn't, return true
		return 0
	fi
	if [[ ! -f ${file} && -f ${timestamp_file} ]]; then
		# File doesn't exist but timestamp does, return true
		return 0
	fi
	# File exists and timestamp exists
	if [[ $(${STAT} -c %Y "${file}") != $(${STAT} -c %Y "${timestamp_file}") ]]; then
		# Timestamp doesn't match file
		if cmp -s "${file}" "${timestamp_file}"; then
			# Files are identical, update timestamp and return false
			touch -r "${file}" "${timestamp_file}"
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
		cp -a "${file}" "${timestamp_file}"
	else
		# Timestamp exists, update it
		touch -r "${file}" "${timestamp_file}"
	fi
	return 1
}

test_needs_yml_merge() {
	warn "CI does not test needs_yml_merge."
}
