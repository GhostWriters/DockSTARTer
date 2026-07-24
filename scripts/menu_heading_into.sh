#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_heading_into() {
	local -n _mhi_out_="${1}"
	assert_nameref_is_string "${1}"
	shift

	local _mhi_AppName_=${1-}
	local _mhi_VarName_=${2-}
	local _mhi_OriginalValue_=${3-}
	local _mhi_CurrentValue_=${4-}

	local -A _mhi_Label_=(
		[Application]="Application: "
		[Filename]="File: "
		[Variable]="Variable: "
		[OriginalValue]="Original Value: "
		[CurrentValue]="Current Value: "
	)
	local -A _mhi_Tag_=(
		[AppDeprecated]="{{|HeadingTag|}}[*DEPRECATED*]{{[-]}}"
		[AppDisabled]="{{|HeadingTag|}}(Disabled){{[-]}}"
		[AppUserDefined]="{{|HeadingTag|}}(User Defined){{[-]}}"
		[VarUserDefined]="{{|HeadingTag|}}(User Defined){{[-]}}"
	)
	local -i _mhi_LabelWidth_=0
	local _mhi_LabelName_ _mhi_LabelText_
	for _mhi_LabelText_ in "${_mhi_Label_[@]}"; do
		if [[ ${#_mhi_LabelText_} -gt _mhi_LabelWidth_ ]]; then
			_mhi_LabelWidth_=${#_mhi_LabelText_}
		fi
	done
	local _mhi_tmp_
	for _mhi_LabelName_ in "${!_mhi_Label_[@]}"; do
		_mhi_LabelText_="${_mhi_Label_["${_mhi_LabelName_}"]}"
		printf -v _mhi_tmp_ "%${_mhi_LabelWidth_}s" "${_mhi_LabelText_}"
		_mhi_Label_["${_mhi_LabelName_}"]="${_mhi_tmp_}"
	done
	local _mhi_Indent_
	printf -v _mhi_Indent_ "%${_mhi_LabelWidth_}s" ""
	local -A _mhi_Heading_=()

	local _mhi_AppIsValid_ _mhi_AppIsDeprecated_ _mhi_AppIsDisabled_ _mhi_AppIsUserDefined_
	local _mhi_VarIsValid_ _mhi_VarIsUserDefined_
	local _mhi_VarFile_ _mhi_DefaultVarFile_

	if [[ -n ${_mhi_AppName_-} ]] && ! run_script 'appname_is_valid' "${_mhi_AppName_}"; then
		_mhi_AppIsValid_=''
	else
		if [[ ${_mhi_AppName_-} == ":"* ]]; then
			_mhi_AppName_="${_mhi_AppName_#:*}"
			_mhi_VarFile_="${COMPOSE_ENV}"
			run_script 'app_instance_file_into' _mhi_DefaultVarFile_ "${_mhi_AppName_}" ".env"
		elif [[ ${_mhi_AppName_-} == *":" ]]; then
			_mhi_AppName_="${_mhi_AppName_%:*}"
			run_script 'app_env_file_into' _mhi_VarFile_ "${_mhi_AppName_}"
			run_script 'app_instance_file_into' _mhi_DefaultVarFile_ "${_mhi_AppName_}" ".env.app.*"
		fi
		if [[ -n ${_mhi_VarName_-} ]] && run_script 'varname_is_valid' "${_mhi_VarName_}"; then
			_mhi_VarIsValid_='Y'
			if [[ ${_mhi_VarName_} == *":"* ]]; then
				_mhi_AppName_="${_mhi_VarName_%:*}"
				_mhi_VarName_="${_mhi_VarName_#*:}"
				run_script 'app_env_file_into' _mhi_VarFile_ "${_mhi_AppName_}"
				run_script 'app_instance_file_into' _mhi_DefaultVarFile_ "${_mhi_AppName_}" ".env.app.*"
			fi
			if [[ -z ${_mhi_VarFile_-} ]]; then
				_mhi_VarFile_="${COMPOSE_ENV}"
				run_script 'app_instance_file_into' _mhi_DefaultVarFile_ "${_mhi_AppName_}" ".env"
			fi
		fi

		if [[ -n ${_mhi_AppName_-} ]] && run_script 'appname_is_valid' "${_mhi_AppName_}"; then
			_mhi_AppIsValid_="Y"
			if run_script 'app_is_user_defined' "${_mhi_AppName_}"; then
				_mhi_AppIsUserDefined_='Y'
				if [[ -n ${_mhi_VarIsValid_-} ]]; then
					_mhi_VarIsUserDefined_='Y'
				fi
			else
				if run_script 'app_is_disabled' "${_mhi_AppName_}"; then
					_mhi_AppIsDisabled_='Y'
				fi
				if run_script 'app_is_deprecated' "${_mhi_AppName_}"; then
					_mhi_AppIsDeprecated_='Y'
				fi
				if [[ -n ${_mhi_VarIsValid_-} && -n ${_mhi_DefaultVarFile_-} ]] && ! run_script 'env_var_exists' "${_mhi_VarName_}" "${_mhi_DefaultVarFile_}"; then
					_mhi_VarIsUserDefined_='Y'
				fi
			fi
			run_script 'app_nicename_into' _mhi_AppName_ "${_mhi_AppName_}"
		else
			_mhi_VarFile_="${COMPOSE_ENV}"
			_mhi_DefaultVarFile_="${COMPOSE_ENV_DEFAULT_FILE}"
			if [[ -n ${_mhi_VarIsValid_-} ]] && ! run_script 'env_var_exists' "${_mhi_VarName_}" "${_mhi_DefaultVarFile_}"; then
				_mhi_VarIsUserDefined_='Y'
			fi
		fi
	fi

	local _mhi_Highlight_="{{|HeadingValue|}}"
	for _mhi_LabelName_ in CurrentValue OriginalValue Variable Filename Application; do
		case "${_mhi_LabelName_}" in
			Application)
				if [[ -n ${_mhi_AppName_-} ]]; then
					_mhi_Heading_[Application]="{{[-]}}${_mhi_Label_[Application]}${_mhi_Highlight_}${_mhi_AppName_}{{[-]}}"
					if [[ ${_mhi_AppIsValid_-} == "Y" ]]; then
						if [[ ${_mhi_AppIsDeprecated_-} == "Y" ]]; then
							_mhi_Heading_[Application]+=" {{|HeadingTag|}}${_mhi_Tag_[AppDeprecated]}{{[-]}}"
						fi
						if [[ ${_mhi_AppIsDisabled_-} == "Y" ]]; then
							_mhi_Heading_[Application]+=" {{|HeadingTag|}}${_mhi_Tag_[AppDisabled]}{{[-]}}"
						fi
						if [[ ${_mhi_AppIsUserDefined_-} == "Y" ]]; then
							_mhi_Heading_[Application]+=" {{|HeadingTag|}}${_mhi_Tag_[AppUserDefined]}{{[-]}}"
						fi
						_mhi_Heading_[Application]+="\n"

						local _mhi_AppDescription_
						run_script 'app_description_into' _mhi_AppDescription_ "${_mhi_AppName_}"
						set_screen_size
						local -i _mhi_ScreenCols_=${COLUMNS}
						local -i _mhi_TextWidth_=$((_mhi_ScreenCols_ - D["WindowColsAdjust"] - D["TextColsAdjust"] - _mhi_LabelWidth_))
						local -a _mhi_AppDesciptionArray_
						readarray -t _mhi_AppDesciptionArray_ < <(wordwrap "${_mhi_AppDescription_}" ${_mhi_TextWidth_})
						local _mhi_DescriptionLine_
						for _mhi_DescriptionLine_ in "${_mhi_AppDesciptionArray_[@]-}"; do
							_mhi_Heading_[Application]+="${_mhi_Indent_}{{|HeadingAppDescription|}}${_mhi_DescriptionLine_}{{[-]}}\n"
						done
					fi
					_mhi_Heading_[Application]+="\n"
					_mhi_Highlight_="{{|Heading|}}"
				fi
				;;
			Filename)
				if [[ -n ${_mhi_VarFile_-} ]]; then
					_mhi_Heading_[Filename]="{{[-]}}${_mhi_Label_[Filename]}${_mhi_Highlight_}${_mhi_VarFile_}{{[-]}}\n"
					_mhi_Highlight_="{{|Heading|}}"
				fi
				;;
			Variable)
				if [[ -n ${_mhi_VarName_-} ]]; then
					_mhi_Heading_[Variable]="{{[-]}}${_mhi_Label_[Variable]}${_mhi_Highlight_}${_mhi_VarName_}{{[-]}}"
					if [[ ${_mhi_VarIsUserDefined_-} == "Y" ]]; then
						_mhi_Heading_[Variable]+=" {{|HeadingTag|}}${_mhi_Tag_[VarUserDefined]}{{[-]}}"
					fi
					_mhi_Heading_[Variable]+="\n"
					_mhi_Highlight_="{{|Heading|}}"
				fi
				;;
			OriginalValue)
				if [[ -n ${_mhi_OriginalValue_-} ]]; then
					_mhi_Heading_[OriginalValue]="\n${_mhi_Label_[OriginalValue]}${_mhi_Highlight_}${_mhi_OriginalValue_}{{[-]}}\n"
					_mhi_Highlight_="{{|Heading|}}"
				fi
				;;
			CurrentValue)
				if [[ -n ${_mhi_CurrentValue_-} ]]; then
					_mhi_Heading_[CurrentValue]="${_mhi_Label_[CurrentValue]}${_mhi_Highlight_}${_mhi_CurrentValue_}{{[-]}}\n"
					_mhi_Highlight_="{{|Heading|}}"
				fi
				;;
		esac
	done
	local _mhi_formatted_
	printf -v _mhi_formatted_ '%b' "${_mhi_Heading_[Application]-}${_mhi_Heading_[Filename]-}${_mhi_Heading_[Variable]-}${_mhi_Heading_[OriginalValue]-}${_mhi_Heading_[CurrentValue]-}"
	_mhi_out_="${_mhi_formatted_%$'\n'}"
}

test_menu_heading_into() {
	warn "CI does not test menu_heading_into."
}
