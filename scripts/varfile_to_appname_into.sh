#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

# Returns the bare app name a ".env.app.*" filename belongs to -- the
# filename's own suffix may itself be service/shared-qualified (e.g.
# "immich___postgres", "immich-database"), identifying a real per-service
# file or a shared/virtual grouping file rather than the plain one; that
# qualifier is stripped here so discovery credits the app the file actually
# belongs to, not the raw qualified string (which would just fail
# appname_is_valid below and be dropped silently).
varfile_to_appname_into() {
	local -n _vtai_out_="${1}"
	assert_nameref_is_string "${1}"
	_vtai_out_=""
	local _vtai_VarFile_="${2-}"
	local _vtai_FileName_="${_vtai_VarFile_##*/}"
	local _vtai_Prefix_='.env.app.'
	local _vtai_Qualified_="${_vtai_FileName_#"${_vtai_Prefix_}"}"
	if [[ -n ${_vtai_Qualified_} && ${_vtai_Qualified_} != "${_vtai_FileName_}" && ${_vtai_Qualified_} == "${_vtai_Qualified_,,}" ]]; then
		local _vtai_AppName_
		run_script 'appname_strip_service_suffix_into' _vtai_AppName_ "${_vtai_Qualified_}"
		if run_script 'appname_is_valid' "${_vtai_AppName_}"; then
			_vtai_out_="${_vtai_AppName_}"
		fi
	fi
}

test_varfile_to_appname_into() {
	local -a Tests=(
		.env.app.sonarr "sonarr"
		.env.app.sonarr__4k "sonarr__4k"
		.env.app.immich___postgres "immich"
		.env.app.immich-database "immich"
		.env.app "" # no suffix at all
		notanenvfile ""
	)
	local -i result=0
	for ((i = 0; i < ${#Tests[@]}; i += 2)); do
		local Result
		run_script 'varfile_to_appname_into' Result "${Tests[i]}"
		if [[ ${Result} != "${Tests[i + 1]}" ]]; then
			error "[${Tests[i]}]: expected [${Tests[i + 1]}] got [${Result}]"
			result=1
		else
			notice "[${Tests[i]}] = [${Result}]"
		fi
	done
	return ${result}
}
