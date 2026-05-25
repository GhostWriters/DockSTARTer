#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

config_ini_set() {
	# config_ini_set KEY VALUE [CONFIG_FILE]
	# Writes a flat KEY=VALUE pair into an INI file (no section grouping).
	# Used for app configs like sabnzbd.ini and qBittorrent.conf where
	# section-aware editing is not required at the entry-point level.
	local key=${1-}
	local value=${2-}
	local config_file=${3-}

	if [[ -z ${key} || -z ${config_file} ]]; then
		error "config_ini_set requires KEY and CONFIG_FILE."
		return 1
	fi

	set_ini_val "${config_file}" "${key}" "${value}"
}

test_config_ini_set() {
	local TempFile
	TempFile=$(mktemp -t "${APPLICATION_NAME}.test_config_ini_set.XXXXXXXXXX")
	printf 'existing=oldvalue\nother=present\n' > "${TempFile}"

	run_script 'config_ini_set' "existing" "newvalue" "${TempFile}"
	run_script 'config_ini_set' "fresh" "added" "${TempFile}"

	local -i result=0
	if ! grep -q '^existing=newvalue$' "${TempFile}"; then
		error "Existing key not updated."
		result=1
	fi
	if ! grep -q '^fresh=added$' "${TempFile}"; then
		error "New key not appended."
		result=1
	fi
	if ! grep -q '^other=present$' "${TempFile}"; then
		error "Untouched key was modified."
		result=1
	fi
	rm -f "${TempFile}"
	return ${result}
}
