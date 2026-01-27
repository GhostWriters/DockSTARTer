#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=(
	grep
)

appvars_sanitize() {
	local AppName=${1-}
	local -a VarsToUpdate
	local -A UpdatedVarValue

	local BaseAppName
	BaseAppName="$(run_script 'appname_to_baseappname' "${AppName}")"
	if [[ ${BaseAppName^^} == WATCHTOWER ]]; then
		# Don't set WATCHTOWER__NETWORK_MODE to none
		local VarName="${AppName^^}__NETWORK_MODE"
		local Value
		Value="$(run_script 'env_get' "${VarName}")"
		if [[ ${Value-} == "none" ]]; then
			VarsToUpdate+=("${VarName}")
			UpdatedVarValue["${VarName}"]="''"
		fi
	fi

	# Add any "APPNAME__VOLUME_*" variables to the list
	local -a VarList
	readarray -t VarList < <(
		${GREP} -o -P "^\s*\K${AppName^^}__VOLUME_[a-zA-Z0-9]+[a-zA-Z0-9_]*(?=\s*=)" "${COMPOSE_ENV}" || true
	)
	for VarName in "${VarList[@]}"; do
		# Get the value including quotes
		local Value
		Value="$(run_script 'env_get_literal' "${VarName}")"
		local UpdatedValue
		UpdatedValue="$(run_script 'sanitize_path' "${Value}")"
		if [[ ${Value} != "${UpdatedValue}" ]]; then
			VarsToUpdate+=("${VarName}")
			UpdatedVarValue["${VarName}"]="${UpdatedValue}"
		fi
	done

	if [[ -n ${VarsToUpdate[*]-} ]]; then
		notice "Setting variables in ${C["File"]}${COMPOSE_ENV}${NC}:"
		for VarName in "${VarsToUpdate[@]}"; do
			local Value="${UpdatedVarValue["${VarName}"]}"
			notice "   ${C["Var"]}${VarName}=${Value}${NC}"
			run_script 'env_set_literal' "${VarName}" "${Value}"
		done
	fi
}

test_appvars_sanitize() {
	run_script 'appvars_create' WATCHTOWER
	run_script 'appvars_sanitize' WATCHTOWER
}
