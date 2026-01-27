#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=(
	grep
)

env_get_and_expand() {
	# env_get_and_expand VarName [VarFile] [VarName] [VarValue]...
	local VarName="${1-}"
	local VarFile="${2:-$COMPOSE_ENV}"
	if [[ $# -ge 2 ]]; then
		shift 2
	else
		shift $#
	fi
	local String=""
	String="$(run_script 'env_get' "${VarName}" "${VarFile}")"
	if [[ -z ${String} ]]; then
		return
	fi
	expand_vars_using_varfile "${String}" "${VarName}" "${VarFile}" "${@}"
}

test_env_get_and_expand() {
	warn "CI does not test env_get_and_expand."
}
