#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=(
	grep
)

var_helpline() {
	# Returns a short one-line description for a variable name.
	# Mirrors the Go GetVarHelpLine logic in internal/appenv/varhelp.go.
	#
	# Input may be in any of these forms:
	#   DOCKER_GID                   (global var, plain)
	#   WATCHTOWER__ENABLED          (app var, plain)
	#   WATCHTOWER:WATCHTOWER__ENABLED  (app var, with APPNAME: prefix from menu_config_vars)
	local VarName=${1-}

	# Strip APPNAME: prefix (menu_config_vars internal convention)
	VarName="${VarName#*:}"
	VarName="${VarName^^}"

	# Use varname_to_appname to distinguish global vs app var (mirrors VarNameToAppName in Go)
	local APPNAME
	APPNAME="$(run_script 'varname_to_appname' "${VarName}")"
	APPNAME="${APPNAME^^}"

	if [[ -z ${APPNAME} ]]; then
		# GLOBAL variable — exact name match
		case "${VarName}" in
			DOCKER_GID)
				echo "The {{|Highlight|}}Docker group ID{{[-]}} on your system."
				;;
			DOCKER_HOSTNAME)
				echo "Your {{|Highlight|}}system hostname{{[-]}}."
				;;
			DOCKER_VOLUME_CONFIG)
				echo "Path to the application {{|Highlight|}}config data{{[-]}} directory."
				;;
			DOCKER_VOLUME_STORAGE)
				echo "Path to the application {{|Highlight|}}storage data{{[-]}} directory."
				;;
			GLOBAL_LAN_NETWORK)
				echo "Your home LAN network in CIDR notation (e.g. {{|Highlight|}}192.168.1.0/24{{[-]}})."
				;;
			PGID)
				echo "Your {{|Highlight|}}user group ID{{[-]}}."
				;;
			PUID)
				echo "Your {{|Highlight|}}user account ID{{[-]}}."
				;;
			TZ)
				echo "Your {{|Highlight|}}system timezone{{[-]}} (e.g. {{|Highlight|}}America/New_York{{[-]}})."
				;;
		esac
	else
		# APP variable — extract the suffix after APPNAME__
		local Suffix="${VarName#"${APPNAME}__"}"
		case "${Suffix}" in
			ENABLED)
				echo "Enable or disable this application ({{|Highlight|}}true{{[-]}}/{{|Highlight|}}false{{[-]}})."
				;;
			NETWORK_MODE)
				echo "Docker network mode (blank, {{|Highlight|}}bridge{{[-]}}, {{|Highlight|}}host{{[-]}}, {{|Highlight|}}none{{[-]}}, {{|Highlight|}}service:X{{[-]}}, {{|Highlight|}}container:X{{[-]}})."
				;;
			RESTART)
				echo "Container restart policy ({{|Highlight|}}unless-stopped{{[-]}}, {{|Highlight|}}no{{[-]}}, {{|Highlight|}}always{{[-]}}, {{|Highlight|}}on-failure{{[-]}})."
				;;
			TAG)
				echo "Docker image tag (usually {{|Highlight|}}latest{{[-]}})."
				;;
			VOLUME_*)
				echo "Path to a volume directory for this application."
				;;
			*)
				if [[ ${Suffix} =~ ^PORT_[0-9]+$ ]]; then
					echo "A port number between {{|Highlight|}}0{{[-]}} and {{|Highlight|}}65535{{[-]}}."
				fi
				;;
		esac
	fi
}

test_var_helpline() {
	notice "[DOCKER_GID]                    = [$(run_script 'var_helpline' DOCKER_GID)]"
	notice "[TZ]                            = [$(run_script 'var_helpline' TZ)]"
	notice "[GLOBAL_LAN_NETWORK]            = [$(run_script 'var_helpline' GLOBAL_LAN_NETWORK)]"
	notice "[SONARR__ENABLED]               = [$(run_script 'var_helpline' SONARR__ENABLED)]"
	notice "[SONARR__NETWORK_MODE]          = [$(run_script 'var_helpline' SONARR__NETWORK_MODE)]"
	notice "[SONARR__VOLUME_CONFIG]         = [$(run_script 'var_helpline' SONARR__VOLUME_CONFIG)]"
	notice "[SONARR__PORT_0]                = [$(run_script 'var_helpline' SONARR__PORT_0)]"
	notice "[SONARR:SONARR__ENABLED]        = [$(run_script 'var_helpline' 'SONARR:SONARR__ENABLED')]"
	notice "[SONARR__4K__ENABLED]           = [$(run_script 'var_helpline' SONARR__4K__ENABLED)]"
	notice "[SONARR__UNKNOWN]               = [$(run_script 'var_helpline' SONARR__UNKNOWN)]"
}
