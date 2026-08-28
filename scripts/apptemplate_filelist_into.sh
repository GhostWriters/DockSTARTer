#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=(
	find
)

# Returns the ".env.app.*" filename TEMPLATES an app ships -- one entry per
# real per-service file ("___service") or shared/virtual file ("-suffix")
# alongside the plain one, each as a "*"-wildcarded pattern (e.g.
# ".env.app.*___postgres") suitable for passing straight to
# app_instance_file_into, which itself substitutes "*" for the base app
# name (template folder) or the full instance-qualified app name (instance
# file). appvars_filelist_into is the equivalent for files that already
# exist in COMPOSE_FOLDER; this is the template-side source of truth for
# which files an app SHOULD have, used when creating them for the first
# time. APPNAME may be instance-qualified -- only the base app's own
# template folder is scanned, since instance-qualified apps have no
# template folder of their own (see app_instance_file_into).
apptemplate_filelist_into() {
	local -n _atfi_out_="${1}"
	assert_nameref_is_array "${1}"
	local -l _atfi_appname_=${2-}
	_atfi_out_=()

	local -l _atfi_baseapp_
	run_script 'appname_to_baseappname_into' _atfi_baseapp_ "${_atfi_appname_}"

	local _atfi_TemplateFolder_="${TEMPLATES_FOLDER}/${_atfi_baseapp_}"
	[[ -d ${_atfi_TemplateFolder_} ]] || return 0

	local _atfi_Prefix_='.env.app.'
	local -a _atfi_Entries_
	readarray -t _atfi_Entries_ < <(
		${FIND} "${_atfi_TemplateFolder_}" -maxdepth 1 -type f -name "${_atfi_Prefix_}*" ! -name "${_atfi_Prefix_}" 2> /dev/null | sort
	)

	local _atfi_Entry_
	for _atfi_Entry_ in "${_atfi_Entries_[@]}"; do
		[[ -n ${_atfi_Entry_} ]] || continue
		local _atfi_FileName_
		_atfi_FileName_="$(basename "${_atfi_Entry_}")"
		# Single substitution: the base app name only ever appears once, as
		# the file's own app-name segment (e.g. "immich" in
		# ".env.app.immich___postgres" -> ".env.app.*___postgres").
		_atfi_out_+=("${_atfi_FileName_/"${_atfi_baseapp_}"/\*}")
	done
}

test_apptemplate_filelist_into() {
	local -a Templates
	run_script 'apptemplate_filelist_into' Templates "IMMICH"
	notice "IMMICH: [${Templates[*]-}]"
	run_script 'apptemplate_filelist_into' Templates "immich__myinstance"
	notice "immich__myinstance: [${Templates[*]-}]"
	run_script 'apptemplate_filelist_into' Templates "WATCHTOWER"
	notice "WATCHTOWER: [${Templates[*]-}]"
	run_script 'apptemplate_filelist_into' Templates "NONEXISTENTAPP"
	notice "NONEXISTENTAPP: [${Templates[*]-}]"
}
