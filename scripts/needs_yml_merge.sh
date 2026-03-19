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
	# Sentinel file for YML merge (use docker-compose.yml marker as reference)
	local SentinelFile="${timestamps_folder}/docker-compose.yml"

	for AppName in $(run_script 'app_list_enabled'); do
		local -l appname=${AppName}
		if file_changed "$(run_script 'app_env_file' "${appname}")"; then
			# .env.app.appname has changed, return true
			return 0
		fi

		# Check app-specific template directory
		if [[ -f ${SentinelFile} ]]; then
			local baseappname
			baseappname="$(run_script 'appname_to_baseappname' "${appname}")"
			local AppTemplateDir="${TEMPLATES_FOLDER:?}/${baseappname}"
			if [[ -d ${AppTemplateDir} ]]; then
				if [[ -n $(find "${AppTemplateDir}" -newer "${SentinelFile}" -print -quit) ]]; then
					return 0
				fi
			fi
		fi
	done

	# No files have changed, return false
	return 1
}

file_changed() {
	local file=${1-}
	local timestamp_file
	timestamp_file="${timestamps_folder}/$(basename "${file}")"

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

test_needs_yml_merge() {
	warn "CI does not test needs_yml_merge."
}
