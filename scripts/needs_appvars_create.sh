#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=(
	stat
)

declare timestamps_folder="${TIMESTAMPS_FOLDER:?}/appvars_create"

needs_appvars_create() {
	if [[ -n ${FORCE-} ]]; then
		return 0
	fi

	# 1. Check Global .env
	if file_changed "${COMPOSE_ENV}"; then
		return 0
	fi

	if [[ $# -eq 0 ]]; then
		# BULK MODE
		# 2. Check Added Apps List
		local AddedAppsFile="${timestamps_folder}/AddedApps"
		if [[ ! -f ${AddedAppsFile} ]] || ! cmp -s "${AddedAppsFile}" <(run_script 'app_list_added'); then
			return 0
		fi

		# 3. Bulk Scan (Templates and App Env Files)
		local SentinelFile="${timestamps_folder}/LastSynced"
		if [[ ! -f ${SentinelFile} ]]; then
			return 0
		fi
		# Check if ANY template file is newer than our last sync
		if [[ -n $(find "${TEMPLATES_FOLDER}" -newer "${SentinelFile}" -print -quit) ]]; then
			return 0
		fi
		# Check if ANY app-specific env file in the root is newer than our last sync
		if [[ -n $(find "${COMPOSE_FOLDER}" -maxdepth 1 -name ".env.app.*" -newer "${SentinelFile}" -print -quit) ]]; then
			return 0
		fi
		return 1
	fi

	# PRECISE MODE (One or more apps)
	for AppName in "$@"; do
		local -l appname=${AppName}
		if ! run_script 'app_is_added' "${appname}"; then
			return 0
		fi

		local AppEnvFile
		AppEnvFile="$(run_script 'app_env_file' "${appname}")"
		if file_changed "${AppEnvFile}"; then
			return 0
		fi

		local baseappname
		baseappname="$(run_script 'appname_to_baseappname' "${appname}")"
		local AppTemplateDir="${TEMPLATES_FOLDER:?}/${baseappname}"

		local GlobalSentinel="${timestamps_folder}/LastSynced"
		local AppSentinel="${timestamps_folder}/LastSynced_${appname^^}"
		local NewestSentinel="${AppSentinel}"
		if [[ -f ${GlobalSentinel} ]]; then
			if [[ ! -f ${AppSentinel} ]] || [[ ${GlobalSentinel} -nt ${AppSentinel} ]]; then
				NewestSentinel="${GlobalSentinel}"
			fi
		fi

		if [[ ! -f ${NewestSentinel} ]]; then
			return 0
		fi

		if [[ -d ${AppTemplateDir} ]]; then
			if [[ -n $(find "${AppTemplateDir}" -newer "${NewestSentinel}" -print -quit) ]]; then
				return 0
			fi
		fi
	done

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

test_needs_appvars_create() {
	warn "CI does not test needs_appvars_create."
}
