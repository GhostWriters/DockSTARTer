#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare Prefix="yml_merge_"

unset_needs_yml_merge() {
	if [[ -d ${TIMESTAMPS_FOLDER:?} ]]; then
		rm -f "${TIMESTAMPS_FOLDER:?}/${Prefix}"* &> /dev/null || true
	else
		mkdir "${TIMESTAMPS_FOLDER:?}"
		run_script 'set_permissions' "${TIMESTAMPS_FOLDER:?}"
	fi
	make_timestamp_file "${DOCKER_COMPOSE_FILE}"
	make_timestamp_file "${COMPOSE_ENV}"
	for AppName in $(run_script 'app_list_enabled'); do
		make_timestamp_file "$(run_script 'app_env_file' "${AppName}")"
	done
}

make_timestamp_file() {
	for file in "$@"; do
		if [[ -f ${file} ]]; then
			touch -r "${file}" "${TIMESTAMPS_FOLDER:?}/${Prefix}$(basename "${file}")"
		fi
	done
}

test_unset_needs_yml_merge() {
	warn "CI does not test unset_needs_yml_merge."
}
