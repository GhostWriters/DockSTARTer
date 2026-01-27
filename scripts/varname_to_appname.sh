#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=(
	grep
)

varname_to_appname() {
	# Returns the DS application name based on the variable name passed
	# The appname will be at the beginning of the variable, and will be in upper case
	# The appname will either be a single alphanumeric word beginning with a letter, or two words split by a double underscore
	# The end of the appname will be followed by a double underscore and a word
	# Variable names that do not match these conditions will return an empty string
	# SONARR__CONTAINER_NAME returns SONARR
	# SONARR__4K__CONTAINER_NAME returns SONARR__4K
	# DOCKER_VOLUME_STORAGE returns an empty string

	local VarName=${1-}
	if [[ ${VarName} == *":"* ]]; then
		echo "${VarName%:*}"
	else
		echo "${VarName}" | (${GREP} -o -P '^[A-Z][A-Z0-9]*(__[A-Z0-9]+)?(?=__[A-Za-z0-9])' || true)
	fi
}

test_varname_to_appname() {
	notice "[SONARR_CONTAINER_NAME]            = [$(run_script 'varname_to_appname' SONARR_CONTAINER_NAME)]"            # []
	notice "[SONARR__CONTAINER_NAME]           = [$(run_script 'varname_to_appname' SONARR__CONTAINER_NAME)]"           # [SONARR]
	notice "[SONARR__4K__CONTAINER_NAME]       = [$(run_script 'varname_to_appname' SONARR__4K__CONTAINER_NAME)]"       # [SONARR__4K]
	notice "[SONARR__4K__CONTAINER_NAME__TEST] = [$(run_script 'varname_to_appname' SONARR__4K__CONTAINER_NAME__TEST)]" # [SONARR__4K]
	notice "[SONARR__4K__CONTAINER__NAME]      = [$(run_script 'varname_to_appname' SONARR__4K__CONTAINER__NAME)]"      # [SONARR__4K]
	notice "[SONARR_4K__CONTAINER__NAME]       = [$(run_script 'varname_to_appname' SONARR_4K__CONTAINER__NAME)]"       # []
	notice "[DOCKER_VOLUME_STORAGE]            = [$(run_script 'varname_to_appname' DOCKER_VOLUME_STORAGE)]"            # []
}
