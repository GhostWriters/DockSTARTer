#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

env_list_app_global_defaults() {
	local -l appname=${1-}
	local instance_file
	run_script 'app_instance_file_into' instance_file "${appname}" ".env"
	run_script 'env_var_list' "${instance_file}"
}

test_env_list_app_global_defaults() {
	run_script 'env_list_app_global_defaults' WATCHTOWER
}
