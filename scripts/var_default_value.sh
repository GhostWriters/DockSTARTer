#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

var_default_value() {
	local result
	run_script 'var_default_value_into' result "$@"
	echo "${result}"
}

test_var_default_value() {
	for VarName in NONEXISTENT_GLOBAL_VAR NONEXISTENTAPP__VARNAME NONEXISTENAAPP__PORT_80 NONEXISTENTAPP__HOSTNAME WATCHTOWER__HOSTNAME DOCKER_VOLUME_STORAGE; do
		local Result
		Result="$(run_script 'var_default_value' "${VarName}")"
		echo "${VarName}=${Result}"
	done
	notice "CI does not test var_default_value"
}
