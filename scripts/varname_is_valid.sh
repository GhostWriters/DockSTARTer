#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

varname_is_valid() {
	local VarName=${1-}
	local VarType=${2-}
	case "${VarType^^}" in
		"")
			# <no argument>
			# Accepts any variable type
			run_script 'varname_is_valid' "${VarName}" "_BARE_" || run_script 'varname_is_valid' "${VarName}" "_APPNAME_:"
			return
			;;
		"_BARE_")
			# _BARE_
			# Accepts a bare variable, no appname specified.
			[[ ${VarName} =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]
			return
			;;
		"_GLOBAL_")
			# _GLOBAL_
			# Accepts a global variable.  It connot be a variable for an app
			if run_script 'varname_is_valid' "${VarName}" "_BARE_"; then
				local DetectedApp
				run_script 'varname_to_appname_into' DetectedApp "${VarName}"
				[[ ${DetectedApp} == "" ]]
				return
			fi
			false
			return
			;;
		"_APPNAME_")
			# _APPNAME_
			# Accepts a variable for any app.  It must be upper case, and it must be in the form "APPNAME__VARNAME"
			if run_script 'varname_is_valid' "${VarName}" "_BARE_"; then
				local DetectedApp
				run_script 'varname_to_appname_into' DetectedApp "${VarName}"
				[[ ${DetectedApp} != "" ]]
				return
			fi
			false
			return
			;;
		"_APPNAME_:")
			# _APPNAME_:
			# Accepts a variable in any ".env.app.appname" file (specifies "appname:varname")
			if [[ ${VarName} == *":"* ]]; then
				local AppName="${VarName%:*}"
				# The colon prefix may carry a service/shared qualifier
				# (e.g. "immich-database", "immich___postgres") identifying
				# which .env.app.* file it targets; appname_is_valid only
				# recognizes real app[__instance] names, so validate
				# against the app name with that qualifier stripped.
				local BaseAppName
				run_script 'appname_strip_service_suffix_into' BaseAppName "${AppName}"
				if run_script 'appname_is_valid' "${BaseAppName}"; then
					run_script 'varname_is_valid' "${VarName#"${AppName}:"*}" "_BARE_"
					return
				fi
			fi
			false
			return
			;;
		*":")
			# <appname>:
			# Accepts a variable in ".env.app.appname" file (specifies "appname:varname")
			if [[ ${VarName} == *":"* ]]; then
				local AppName="${VarName%:*}"
				if [[ "${AppName^^}:" == "${VarType^^}" ]]; then
					run_script 'varname_is_valid' "${VarName#"${AppName}:"*}" "_BARE_"
					return
				fi
			fi
			false
			return
			;;
		*)
			# <appname>
			# Accepts a variable for the specified app.  It must be upper case and in the form "APPNAME__VARNAME"
			if run_script 'varname_is_valid' "${VarName}" "_BARE_"; then
				local DetectedApp
				run_script 'varname_to_appname_into' DetectedApp "${VarName}"
				[[ ${DetectedApp} == "${VarType^^}" ]]
				return
			fi
			false
			return
			;;
	esac
}

test_varname_is_valid() {
	for VarType in "" _BARE_ _GLOBAL_ _APPNAME_ "_APPNAME_:" "radarr:" "radarr"; do
		notice "[${VarType}]"
		for VarName in "2radarr:radarr" "radarr:varname" 2TZ TZ RADARR__TEST RADARR_4K RADARR__TAG Radarr__TAG RADARR__4K__TAG RADARR__4K__tag; do
			if run_script 'varname_is_valid' "${VarName}" "${VarType}"; then
				notice "             [*VALID*] [${VarName}]"
			else
				notice "                       [${VarName}]"
			fi
		done
	done

	# Multi-service: a service/shared-qualified colon prefix must validate
	# against "_APPNAME_:" and its own exact qualified VarType, same as a
	# plain appname does -- this is the exact bug class confirmed live on
	# DockSTARTer2 (2026-08-28) where the equivalent unstripped check always
	# rejected these.
	local -i result=0
	local -a Tests=(
		"immich-database:DB_HOSTNAME" "_APPNAME_:" 0
		"immich-database:DB_HOSTNAME" "immich-database:" 0
		"immich___postgres:POSTGRES_DB" "_APPNAME_:" 0
		"immich___postgres:POSTGRES_DB" "immich___postgres:" 0
	)
	for ((i = 0; i < ${#Tests[@]}; i += 3)); do
		local VarName="${Tests[i]}" VarType="${Tests[i + 1]}" Expected="${Tests[i + 2]}"
		local -i Actual=1
		run_script 'varname_is_valid' "${VarName}" "${VarType}" && Actual=0
		if [[ ${Actual} != "${Expected}" ]]; then
			error "varname_is_valid(${VarName}, ${VarType}) = ${Actual}; want ${Expected}"
			result=1
		else
			notice "varname_is_valid(${VarName}, ${VarType}) = ${Actual}"
		fi
	done
	return ${result}
}
