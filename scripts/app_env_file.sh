#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=()

app_env_file() {
	local result
	run_script 'app_env_file_into' result "$@"
	echo "${result}"
}

test_app_env_file() {
	for AppName in watchtower radarr radarr__4k; do
		notice "[${AppName}] [$(run_script 'app_env_file' "${AppName}")]"
	done
}
