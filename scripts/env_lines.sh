#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=()

env_lines() {
	local VAR_FILE=${1:-$COMPOSE_ENV}
	if [[ -f ${VAR_FILE} ]]; then
		local line
		while IFS= read -r line; do
			if [[ ${line} =~ ^[[:space:]]*([A-Za-z0-9_]+)[[:space:]]*=(.*) ]]; then
				printf '%s=%s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
			fi
		done < "${VAR_FILE}"
	fi
}

test_env_lines() {
	run_script 'env_lines'
	#warn "CI does not test env_lines."
}
