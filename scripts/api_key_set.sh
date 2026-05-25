#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

api_key_set() {
	# api_key_set SECTION.KEY VALUE
	# Writes a secret to ${API_KEYS_TOML_FILE} (mode 0600), creating
	# the file if needed. Section is typically the app name; key is
	# the secret kind (e.g. "api_key", "nzb_key", "admin_password").
	#
	# Example:
	#   api_key_set "sonarr.api_key" "abc123..."
	#   api_key_set "sabnzbd.nzb_key" "xyz789..."
	local section_key=${1-}
	local value=${2-}

	if [[ -z ${section_key} ]]; then
		error "api_key_set requires SECTION.KEY."
		return 1
	fi

	local Path
	run_script 'state_file_path_into' Path "api_keys.toml"

	if [[ ! -f ${Path} ]]; then
		: > "${Path}"
		chmod 600 "${Path}" || true
	fi

	set_toml_val_string "${Path}" "${section_key}" "${value}"

	# Re-assert mode in case any helper recreated the file.
	chmod 600 "${Path}" || true
}

test_api_key_set() {
	warn "CI does not test api_key_set (modifies persistent state file)."
}
