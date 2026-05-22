#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

sanitize_path_into() {
	local -n _spi_out_="${1}"
	assert_nameref_is_string "${1}"
	local _spi_val_="${2-}"
	if [[ ${_spi_val_} == *~* ]]; then
		_spi_val_="${_spi_val_//\~/"${DETECTED_HOMEDIR}"}"
	fi
	_spi_out_="${_spi_val_}"
}

test_sanitize_path_into() {
	warn "CI does not test sanitize_path_into."
}
