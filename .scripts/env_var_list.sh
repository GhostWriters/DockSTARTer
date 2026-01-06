#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=(
	grep
)

env_var_list() {
	local VAR_FILE=${1:-$COMPOSE_ENV}
	local VAR_REGEX="\w+"
	if [[ -f ${VAR_FILE} ]]; then
		${GREP} --color=never -o -P "^\s*\K${VAR_REGEX}(?=\s*=)" "${VAR_FILE}" || true
	fi
}

test_env_var_list() {
	run_script 'env_var_list'
}
