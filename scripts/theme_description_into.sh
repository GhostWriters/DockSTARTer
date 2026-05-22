#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

theme_description_into() {
	local -n _tdi_out_="${1}"
	local _tdi_ThemeName_="${2-}"

	if [[ -z ${_tdi_ThemeName_} ]]; then
		run_script 'theme_name_into' _tdi_ThemeName_
	fi

	local _tdi_ThemeArchive_
	if [[ ${_tdi_ThemeName_} == file:* ]]; then
		_tdi_ThemeArchive_="${_tdi_ThemeName_#file:}"
	elif [[ ${_tdi_ThemeName_} == user:* ]]; then
		_tdi_ThemeArchive_="${USER_THEMES_FOLDER}/${_tdi_ThemeName_#user:}${THEME_FILE_EXT}"
	else
		_tdi_ThemeArchive_="${THEME_FOLDER}/${_tdi_ThemeName_}${THEME_FILE_EXT}"
	fi

	local _tdi_result_
	hrx_toml_get_into _tdi_result_ "${_tdi_ThemeArchive_}" "${THEME_FILE_NAME}" "metadata.description"
	_tdi_out_="${_tdi_result_}"
}

test_theme_description_into() {
	warn "CI does not test theme_description_into."
}
