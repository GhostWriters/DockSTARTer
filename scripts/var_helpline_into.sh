#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

var_helpline_into() {
	local -n _vhli_out_="${1}"
	local _vhli_VarName_="${2-}"

	_vhli_VarName_="${_vhli_VarName_#*:}"
	_vhli_VarName_="${_vhli_VarName_^^}"

	local _vhli_APPNAME_
	run_script 'varname_to_appname_into' _vhli_APPNAME_ "${_vhli_VarName_}"
	_vhli_APPNAME_="${_vhli_APPNAME_^^}"

	_vhli_out_=""
	if [[ -z ${_vhli_APPNAME_} ]]; then
		case "${_vhli_VarName_}" in
			DOCKER_GID)
				_vhli_out_="The {{|Highlight|}}Docker group ID{{[-]}} on your system."
				;;
			DOCKER_HOSTNAME)
				_vhli_out_="Your {{|Highlight|}}system hostname{{[-]}}."
				;;
			DOCKER_VOLUME_CONFIG)
				_vhli_out_="Path to the application {{|Highlight|}}config data{{[-]}} directory."
				;;
			DOCKER_VOLUME_STORAGE)
				_vhli_out_="Path to the application {{|Highlight|}}storage data{{[-]}} directory."
				;;
			GLOBAL_LAN_NETWORK)
				_vhli_out_="Your home LAN network in CIDR notation (e.g. {{|Highlight|}}192.168.1.0/24{{[-]}})."
				;;
			PGID)
				_vhli_out_="Your {{|Highlight|}}user group ID{{[-]}}."
				;;
			PUID)
				_vhli_out_="Your {{|Highlight|}}user account ID{{[-]}}."
				;;
			TZ)
				_vhli_out_="Your {{|Highlight|}}system timezone{{[-]}} (e.g. {{|Highlight|}}America/New_York{{[-]}})."
				;;
		esac
	else
		local _vhli_Suffix_="${_vhli_VarName_#"${_vhli_APPNAME_}__"}"
		case "${_vhli_Suffix_}" in
			ENABLED)
				_vhli_out_="Enable or disable this application ({{|Highlight|}}true{{[-]}}/{{|Highlight|}}false{{[-]}})."
				;;
			NETWORK_MODE)
				_vhli_out_="Docker network mode (blank, {{|Highlight|}}bridge{{[-]}}, {{|Highlight|}}host{{[-]}}, {{|Highlight|}}none{{[-]}}, {{|Highlight|}}service:X{{[-]}}, {{|Highlight|}}container:X{{[-]}})."
				;;
			RESTART)
				_vhli_out_="Container restart policy ({{|Highlight|}}unless-stopped{{[-]}}, {{|Highlight|}}no{{[-]}}, {{|Highlight|}}always{{[-]}}, {{|Highlight|}}on-failure{{[-]}})."
				;;
			TAG)
				_vhli_out_="Docker image tag (usually {{|Highlight|}}latest{{[-]}})."
				;;
			VOLUME_*)
				_vhli_out_="Path to a volume directory for this application."
				;;
			*)
				if [[ ${_vhli_Suffix_} =~ ^PORT_[0-9]+$ ]]; then
					_vhli_out_="A port number between {{|Highlight|}}0{{[-]}} and {{|Highlight|}}65535{{[-]}}."
				fi
				;;
		esac
	fi
}

test_var_helpline_into() {
	warn "CI does not test var_helpline_into."
}
