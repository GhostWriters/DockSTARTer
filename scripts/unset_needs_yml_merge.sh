#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare timestamps_folder="${TIMESTAMPS_FOLDER:?}/yml_merge"

unset_needs_yml_merge() {
	if [[ -d ${timestamps_folder} ]]; then
		rm -rf "${timestamps_folder:?}/"* &> /dev/null || true
	else
		mkdir -p "${timestamps_folder}"
		run_script 'set_permissions' "${timestamps_folder}"
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
			cp -a "${file}" "${timestamps_folder}/$(basename "${file}")"
		fi
	done
}

test_unset_needs_yml_merge() {
	warn "CI does not test unset_needs_yml_merge."
}
