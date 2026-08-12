#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=(
	find
)

app_list_builtin() {
	local dir name
	while IFS= read -r dir; do
		name="$(basename "${dir}")"
		name="${name^^}"
		if run_script 'appname_is_valid' "${name}"; then
			echo "${name}"
		fi
	done < <(${FIND} "${TEMPLATES_FOLDER}" -maxdepth 1 -mindepth 1 -type d 2> /dev/null || true) | sort
}

test_app_list_builtin() {
	run_script 'app_list_builtin'
	# warn "CI does not test app_list_builtin."
}
