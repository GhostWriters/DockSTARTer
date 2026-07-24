#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=(
	grep
)

varname_to_appname() {
	local result
	run_script 'varname_to_appname_into' result "$@"
	echo "${result}"
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
