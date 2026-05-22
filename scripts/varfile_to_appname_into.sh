#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

varfile_to_appname_into() {
	local -n _vtai_out_="${1}"
	_vtai_out_=""
	local _vtai_VarFile_="${2-}"
	local _vtai_FileName_="${_vtai_VarFile_##*/}"
	local _vtai_Prefix_='.env.app.'
	local _vtai_AppName_="${_vtai_FileName_#"${_vtai_Prefix_}"}"
	if [[ -n ${_vtai_AppName_} && ${_vtai_AppName_} != "${_vtai_FileName_}" && ${_vtai_AppName_} == "${_vtai_AppName_,,}" ]] && run_script 'appname_is_valid' "${_vtai_AppName_}"; then
		_vtai_out_="${_vtai_AppName_}"
	fi
}

test_varfile_to_appname_into() {
	warn "CI does not test varfile_to_appname_into."
}
