#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_heading() {
	local AppName=${1-}
	local VarName=${2-}
	local OriginalValue=${3-}
	local CurrentValue=${4-}

	local -A Label=(
		[Application]="Application: "
		[Filename]="File: "
		[Variable]="Variable: "
		[OriginalValue]="Original Value: "
		[CurrentValue]="Current Value: "
	)
	local -A Tag=(
		[AppDeprecated]="{{|HeadingTag|}}[*DEPRECATED*]{{[-]}}"
		[AppDisabled]="{{|HeadingTag|}}(Disabled){{[-]}}"
		[AppUserDefined]="{{|HeadingTag|}}(User Defined){{[-]}}"
		[VarUserDefined]="{{|HeadingTag|}}(User Defined){{[-]}}"
	)
	local -i LabelWidth=0
	for LabelText in "${Label[@]}"; do
		if [[ ${#LabelText} -gt LabelWidth ]]; then
			LabelWidth=${#LabelText}
		fi
	done
	for LabelName in "${!Label[@]}"; do
		local LabelText="${Label["${LabelName}"]}"
		Label["${LabelName}"]="$(printf "%${LabelWidth}s" "${LabelText}")"
	done
	Indent="$(printf "%${LabelWidth}s" "")"
	local -A Heading=()

	local AppIsValid AppIsDeprecated AppIsDisabled AppIsUserDefined VarIsValid VarIsUserDefined
	local VarFile
	local DefaultVarFile

	if [[ -n ${AppName-} ]] && ! run_script 'appname_is_valid' "${AppName}"; then
		AppIsValid=''
	else
		if [[ ${AppName-} == ":"* ]]; then # ":AppName", using .env
			AppName="${AppName#:*}"
			VarFile="${COMPOSE_ENV}"
			DefaultVarFile="$(run_script 'app_instance_file' "${AppName}" ".env")"
		elif [[ ${AppName-} == *":" ]]; then # "AppName:", using appname.env
			AppName="${AppName%:*}"
			VarFile="$(run_script 'app_env_file' "${AppName}")"
			DefaultVarFile="$(run_script 'app_instance_file' "${AppName}" ".env.app.*")"
		fi
		if [[ -n ${VarName-} ]] && run_script 'varname_is_valid' "${VarName}"; then # "appname:varname", using appname.env
			VarIsValid='Y'
			if [[ ${VarName} == *":"* ]]; then
				AppName="${VarName%:*}"
				VarName="${VarName#*:}"
				VarFile="$(run_script 'app_env_file' "${AppName}")"
				DefaultVarFile="$(run_script 'app_instance_file' "${AppName}" ".env.app.*")"
			fi
			if [[ -z ${VarFile-} ]]; then
				VarFile="${COMPOSE_ENV}"
				DefaultVarFile="$(run_script 'app_instance_file' "${AppName}" ".env")"
			fi
		fi

		if [[ -n ${AppName-} ]] && run_script 'appname_is_valid' "${AppName}"; then
			AppIsValid="Y"
			if run_script 'app_is_user_defined' "${AppName}"; then
				AppIsUserDefined='Y'
				if [[ -n ${VarIsValid-} ]]; then
					VarIsUserDefined='Y'
				fi
			else
				if run_script 'app_is_disabled' "${AppName}"; then
					AppIsDisabled='Y'
				fi
				if run_script 'app_is_deprecated' "${AppName}"; then
					AppIsDeprecated='Y'
				fi
				if [[ -n ${VarIsValid-} && -n ${DefaultVarFile-} ]] && ! run_script 'env_var_exists' "${VarName}" "${DefaultVarFile}"; then
					VarIsUserDefined='Y'
				fi
			fi
			AppName=$(run_script 'app_nicename' "${AppName}")
		else # Global File or Variable
			VarFile="${COMPOSE_ENV}"
			DefaultVarFile="${COMPOSE_ENV_DEFAULT_FILE}"
			if [[ -n ${VarIsValid-} ]] && ! run_script 'env_var_exists' "${VarName}" "${DefaultVarFile}"; then
				VarIsUserDefined='Y'
			fi
		fi
	fi

	local Highlight="{{|HeadingValue|}}"
	for LabelName in CurrentValue OriginalValue Variable Filename Application; do
		case "${LabelName}" in
			Application)
				if [[ -n ${AppName-} ]]; then
					Heading[Application]="{{[-]}}${Label[Application]}${Highlight}${AppName}{{[-]}}"
					if [[ ${AppIsValid-} == "Y" ]]; then
						if [[ ${AppIsDeprecated-} == "Y" ]]; then
							Heading[Application]+=" {{|HeadingTag|}}${Tag[AppDeprecated]}{{[-]}}"
						fi
						if [[ ${AppIsDisabled-} == "Y" ]]; then
							Heading[Application]+=" {{|HeadingTag|}}${Tag[AppDisabled]}{{[-]}}"
						fi
						if [[ ${AppIsUserDefined-} == "Y" ]]; then
							Heading[Application]+=" {{|HeadingTag|}}${Tag[AppUserDefined]}{{[-]}}"
						fi
						Heading[Application]+="\n"

						local AppDescription
						AppDescription="$(run_script 'app_description' "${AppName}")"
						set_screen_size
						local -i ScreenCols=${COLUMNS}
						local -i TextWidth=$((ScreenCols - D["WindowColsAdjust"] - D["TextColsAdjust"] - LabelWidth))
						local -a AppDesciptionArray
						readarray -t AppDesciptionArray < <(wordwrap "${AppDescription}" ${TextWidth})
						local DescriptionLine
						for DescriptionLine in "${AppDesciptionArray[@]-}"; do
							Heading[Application]+="${Indent}{{|HeadingAppDescription|}}${DescriptionLine}{{[-]}}\n"
						done
					fi
					Heading[Application]+="\n"
					Highlight="{{|Heading|}}"
				fi
				;;
			Filename)
				if [[ -n ${VarFile-} ]]; then
					Heading[Filename]="{{[-]}}${Label[Filename]}${Highlight}${VarFile}{{[-]}}\n"
					Highlight="{{|Heading|}}"
				fi
				;;
			Variable)
				if [[ -n ${VarName-} ]]; then
					Heading[Variable]="{{[-]}}${Label[Variable]}${Highlight}${VarName}{{[-]}}"
					if [[ ${VarIsUserDefined-} == "Y" ]]; then
						Heading[Variable]+=" {{|HeadingTag|}}${Tag[VarUserDefined]}{{[-]}}"
					fi
					Heading[Variable]+="\n"
					Highlight="{{|Heading|}}"
				fi
				;;
			OriginalValue)
				if [[ -n ${OriginalValue-} ]]; then
					Heading[OriginalValue]="\n${Label[OriginalValue]}${Highlight}${OriginalValue}{{[-]}}\n"
					Highlight="{{|Heading|}}"
				fi
				;;
			CurrentValue)
				if [[ -n ${CurrentValue-} ]]; then
					Heading[CurrentValue]="${Label[CurrentValue]}${Highlight}${CurrentValue}{{[-]}}\n"
					Highlight="{{|Heading|}}"
				fi
				;;
		esac
	done
	printf '%b' "${Heading[Application]-}${Heading[Filename]-}${Heading[Variable]-}${Heading[OriginalValue]-}${Heading[CurrentValue]-}"

}

test_menu_heading() {
	run_script 'config_theme'
	notice WATCHTOWER:
	run_script 'menu_heading' WATCHTOWER
	notice "WATCHTOWER WATCHTOWER__ENABLED:"
	run_script 'menu_heading' WATCHTOWER WATCHTOWER__ENABLED
	notice "'' DOCKER_VOLUME_STORAGE:"
	run_script 'menu_heading' '' DOCKER_VOLUME_STORAGE
	notice ":"
	run_script 'menu_heading'
	warn "CI does not test app_is_nondeprecated."
}
