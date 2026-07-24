#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

theme_author_into() {
	local -n _tai_out_="${1}"
	assert_nameref_is_string "${1}"
	local _tai_ThemeName_="${2-}"

	if [[ -z ${_tai_ThemeName_} ]]; then
		run_script 'theme_name_into' _tai_ThemeName_
	fi

	local _tai_ThemeArchive_
	if [[ ${_tai_ThemeName_} == file:* ]]; then
		_tai_ThemeArchive_="${_tai_ThemeName_#file:}"
	elif [[ ${_tai_ThemeName_} == user:* ]]; then
		_tai_ThemeArchive_="${USER_THEMES_FOLDER}/${_tai_ThemeName_#user:}${THEME_FILE_EXT}"
	else
		_tai_ThemeArchive_="${THEME_FOLDER}/${_tai_ThemeName_}${THEME_FILE_EXT}"
	fi

	local _tai_result_
	hrx_toml_get_into _tai_result_ "${_tai_ThemeArchive_}" "${THEME_FILE_NAME}" "metadata.author"
	_tai_out_="${_tai_result_}"
}

test_theme_author_into() {
	warn "CI does not test theme_author_into."
}
