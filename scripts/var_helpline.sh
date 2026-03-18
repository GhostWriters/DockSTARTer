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
				echo "The ${DC["Highlight"]-}Docker group ID${DC["NC"]-} on your system."
				;;
			DOCKER_HOSTNAME)
				echo "Your ${DC["Highlight"]-}system hostname${DC["NC"]-}."
				;;
			DOCKER_VOLUME_CONFIG)
				echo "Path to the application ${DC["Highlight"]-}config data${DC["NC"]-} directory."
				;;
			DOCKER_VOLUME_STORAGE)
				echo "Path to the application ${DC["Highlight"]-}storage data${DC["NC"]-} directory."
				;;
			GLOBAL_LAN_NETWORK)
				echo "Your home LAN network in CIDR notation (e.g. ${DC["Highlight"]-}192.168.1.0/24${DC["NC"]-})."
				;;
			PGID)
				echo "Your ${DC["Highlight"]-}user group ID${DC["NC"]-}."
				;;
			PUID)
				echo "Your ${DC["Highlight"]-}user account ID${DC["NC"]-}."
				;;
			TZ)
				echo "Your ${DC["Highlight"]-}system timezone${DC["NC"]-} (e.g. ${DC["Highlight"]-}America/New_York${DC["NC"]-})."
				;;
		esac
	else
		# APP variable — extract the suffix after APPNAME__
		local Suffix="${VarName#"${APPNAME}__"}"
		case "${Suffix}" in
			ENABLED)
				echo "Enable or disable this application (${DC["Highlight"]-}true${DC["NC"]-}/${DC["Highlight"]-}false${DC["NC"]-})."
				;;
			NETWORK_MODE)
				echo "Docker network mode (blank, ${DC["Highlight"]-}bridge${DC["NC"]-}, ${DC["Highlight"]-}host${DC["NC"]-}, ${DC["Highlight"]-}none${DC["NC"]-}, ${DC["Highlight"]-}service:X${DC["NC"]-}, ${DC["Highlight"]-}container:X${DC["NC"]-})."
				;;
			RESTART)
				echo "Container restart policy (${DC["Highlight"]-}unless-stopped${DC["NC"]-}, ${DC["Highlight"]-}no${DC["NC"]-}, ${DC["Highlight"]-}always${DC["NC"]-}, ${DC["Highlight"]-}on-failure${DC["NC"]-})."
				;;
			TAG)
				echo "Docker image tag (usually ${DC["Highlight"]-}latest${DC["NC"]-})."
				;;
			VOLUME_*)
				echo "Path to a volume directory for this application."
				;;
			*)
				if [[ ${Suffix} =~ ^PORT_[0-9]+$ ]]; then
					echo "A port number between ${DC["Highlight"]-}0${DC["NC"]-} and ${DC["Highlight"]-}65535${DC["NC"]-}."
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
