#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=(
	find
)

# Returns the base filenames (not full paths, e.g. ".env.app.immich___postgres")
# of every ".env.app.*" file in COMPOSE_FOLDER that belongs to APPNAME -- the
# plain file, any real per-service file ("___service"), and any shared/
# virtual file ("-suffix"). APPNAME may itself be instance-qualified (e.g.
# "IMMICH__MYINSTANCE"); only that exact app+instance's files match, not a
# different instance of the same app. Matching strips only a service/shared
# marker from each candidate (via appname_strip_service_suffix_into), never
# an instance, so this stays a narrower, more precise match than
# appname_to_baseappname_into. Mirrors DockSTARTer2's AppVarFileNames
# (internal/appenv/listing.go).
appvars_filelist_into() {
	local -n _afli_out_="${1}"
	assert_nameref_is_array "${1}"
	local -u _afli_APPNAME_=${2-}
	_afli_out_=()

	local _afli_Prefix_='.env.app.'
	local -a _afli_Entries_
	readarray -t _afli_Entries_ < <(
		${FIND} "${COMPOSE_FOLDER}" -maxdepth 1 -type f -name "${_afli_Prefix_}*" ! -name "${_afli_Prefix_}" 2> /dev/null | sort
	)

	local _afli_Entry_
	for _afli_Entry_ in "${_afli_Entries_[@]}"; do
		[[ -n ${_afli_Entry_} ]] || continue
		local _afli_FileName_
		_afli_FileName_="$(basename "${_afli_Entry_}")"
		local -u _afli_Suffix_="${_afli_FileName_#"${_afli_Prefix_}"}"
		local _afli_Base_
		run_script 'appname_strip_service_suffix_into' _afli_Base_ "${_afli_Suffix_}"
		if [[ ${_afli_Base_} == "${_afli_APPNAME_}" ]]; then
			_afli_out_+=("${_afli_FileName_}")
		fi
	done
}

test_appvars_filelist_into() {
	local -a Files
	run_script 'appvars_filelist_into' Files "IMMICH"
	notice "IMMICH: [${Files[*]-}]"
	run_script 'appvars_filelist_into' Files "WATCHTOWER"
	notice "WATCHTOWER: [${Files[*]-}]"
	run_script 'appvars_filelist_into' Files "NONEXISTENTAPP"
	notice "NONEXISTENTAPP: [${Files[*]-}]"
}
