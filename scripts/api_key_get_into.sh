#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

api_key_get_into() {
	# api_key_get_into OutVar SECTION.KEY
	# Reads a secret from ${API_KEYS_TOML_FILE}.
	# Returns non-zero if the file or key does not exist.
	local -n _akgi_out_="${1}"
	assert_nameref_is_string "${1}"
	local _akgi_section_key_=${2-}

	_akgi_out_=""

	if [[ -z ${_akgi_section_key_} ]]; then
		return 1
	fi

	if [[ ! -f ${API_KEYS_TOML_FILE} ]]; then
		return 1
	fi

	local _akgi_val_
	_akgi_val_=$(get_toml_val_string "${API_KEYS_TOML_FILE}" "${_akgi_section_key_}" 2> /dev/null) || return 1
	if [[ -z ${_akgi_val_} ]]; then
		return 1
	fi
	_akgi_out_="${_akgi_val_}"
}

test_api_key_get_into() {
	warn "CI does not test api_key_get_into (depends on persistent state file)."
}
