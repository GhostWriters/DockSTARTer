#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

state_file_path_into() {
	# state_file_path_into OutVar Filename
	# Returns the full path to FILENAME under ${APPLICATION_STATE_FOLDER},
	# ensuring the parent folder exists with mode 0700 and ownership
	# DETECTED_PUID:DETECTED_PGID. Use for files that should persist
	# across DockSTARTer runs and contain sensitive data
	# (e.g. api_keys.toml, integration.log).
	local -n _sfpi_out_="${1}"
	assert_nameref_is_string "${1}"
	local _sfpi_filename_=${2-}

	if [[ -z ${_sfpi_filename_} ]]; then
		error "state_file_path_into requires a filename."
		return 1
	fi

	if [[ ! -d ${APPLICATION_STATE_FOLDER} ]]; then
		mkdir -p "${APPLICATION_STATE_FOLDER}" ||
			fatal \
				"Failed to create folder '{{|Folder|}}${APPLICATION_STATE_FOLDER}{{[-]}}'." \
				"Failing command: {{|FailingCommand|}}mkdir -p \"${APPLICATION_STATE_FOLDER}\""
		sudo chown "${DETECTED_PUID}":"${DETECTED_PGID}" "${APPLICATION_STATE_FOLDER}" &> /dev/null || true
		sudo chmod 700 "${APPLICATION_STATE_FOLDER}" &> /dev/null || true
	fi

	_sfpi_out_="${APPLICATION_STATE_FOLDER}/${_sfpi_filename_}"
}

test_state_file_path_into() {
	local Path
	run_script 'state_file_path_into' Path "api_keys.toml"
	if [[ ${Path} != "${APPLICATION_STATE_FOLDER}/api_keys.toml" ]]; then
		error "Unexpected path: ${Path}"
		return 1
	fi
	if [[ ! -d ${APPLICATION_STATE_FOLDER} ]]; then
		error "APPLICATION_STATE_FOLDER was not created."
		return 1
	fi
}
