#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

env_list_app_env_defaults() {
	local -l appname=${1-}
	local _aif_
	run_script 'app_instance_file_into' _aif_ "${appname}" ".env.app.*"
	run_script 'env_var_list' "${_aif_}"
}

test_env_list_app_env_defaults() {
	run_script 'env_list_app_env_defaults' WATCHTOWER
}
