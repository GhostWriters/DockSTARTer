#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

config_theme() {
	local ThemeName=${1-}

	local DefaultThemes=(
		"${APPLICATION_NAME}"
		Default
	)

	if [[ ! -f ${APPLICATION_INI_FILE} ]]; then
		run_script 'config_create'
	fi

	local ThemeFile DialogFile
	if [[ -z ${ThemeName-} ]]; then
		ThemeName="$(run_script 'config_get' Theme)"
		if ! run_script 'theme_exists' "${ThemeName}"; then
			for Name in "${DefaultThemes[@]}"; do
				if run_script 'theme_exists' "${Name}"; then
					ThemeName="${Name}"
					break
				fi
			done
		fi
	fi

	if ! run_script 'theme_exists' "${ThemeName}"; then
		error "${APPLICATION_NAME} theme '${C["Theme"]}${ThemeName}${NC}' does not exist."
		return 1
	fi

	ThemeFile="${THEME_FOLDER}/${ThemeName}/${THEME_FILE_NAME}"
	DialogFile="${THEME_FOLDER}/${ThemeName}/${DIALOGRC_NAME}"

	local _B_='\Z4'   # Blue
	local _C_='\Z6'   # Cyan
	local _G_='\Z2'   # Green
	local _K_='\Z0'   # Black
	local _M_='\Z5'   # Magenta
	local _R_='\Z1'   # Red
	local _W_='\Z7'   # White
	local _Y_='\Z3'   # Yellow
	local _RV_='\Zr'  # Reverse
	local _NRV_='\ZR' # No Reverse
	local _BD_='\Zb'  # Bold
	local _NBD_='\ZB' # No Bold
	local _U_='\Zu'   # Underline
	local _NU_='\ZU'  # No Underline
	local _NC_='\Zn'  # No Color

	declare -Agx DC=()
	DC+=(
		["_defined_"]=1
	)
	DC+=( # Dialog colors
		["B"]="${_B_}"
		["C"]="${_C_}"
		["G"]="${_G_}"
		["K"]="${_K_}"
		["M"]="${_M_}"
		["R"]="${_R_}"
		["W"]="${_W_}"
		["Y"]="${_Y_}"
		["RV"]="${_RV_}"
		["NRV"]="${_NRV_}"
		["BD"]="${_BD_}"
		["NBD"]="${_NBD_}"
		["U"]="${_U_}"
		["NU"]="${_NU_}"
		["NC"]="${_NC_}"
	)
	DC+=( # Dialog positioning adjustment values
		["WindowColsAdjust"]=4
		["WindowRowsAdjust"]=4
		["TextColsAdjust"]=4
		["TextRowsAdjust"]=5
	)

	local -a VarList
	readarray -t VarList < <(run_script 'env_var_list' "${ThemeFile}")
	for VarName in "${VarList[@]-}"; do
		local Value
		Value="$(run_script 'config_get' "${VarName}" "${ThemeFile}")"
		Value="$(
			_B_="${_B_}" _C_="${_C_}" _G_="${_G_}" _K_="${_K_}" _M_="${_M_}" _R_="${_R_}" _W_="${_W_}" _Y_="${_Y_}" \
				_RV_="${_RV_}" _NRV_="${_NRV_}" _BD_="${_BD_}" _NBD_="${_NBD_}" _U_="${_U_}" _NU_="${_NU_}" _NC_="${_NC_}" \
				eval echo "\"$(cat <<< "${Value}")\""
		)"
		DC["${VarName}"]="${Value}"
	done
	DC["ThemeName"]="${ThemeName}"
	local DialogOptions="--colors --output-fd 1 --cr-wrap --no-collapse"

	local LineCharacters Borders Scrollbar Shadow
	if run_script 'env_var_exists' Scrollbar "${APPLICATION_INI_FILE}"; then
		Scrollbar="$(run_script 'config_get' Scrollbar)"
	else
		Scrollbar="$(run_script 'config_get' Scrollbar "${DEFAULT_INI_FILE}")"
		run_script 'config_set' Scrollbar "${Scrollbar}"
	fi
	if run_script 'env_var_exists' Shadow "${APPLICATION_INI_FILE}"; then
		Shadow="$(run_script 'config_get' Shadow)"
	else
		Shadow="$(run_script 'config_get' Shadow "${DEFAULT_INI_FILE}")"
		run_script 'config_set' Shadow "${Shadow}"
	fi
	# Migrate old LineCharacters variable to Borders if Borders doesn't exist
	if run_script 'env_var_exists' Borders "${APPLICATION_INI_FILE}"; then
		Borders="$(run_script 'config_get' Borders)"
		if run_script 'env_var_exists' LineCharacters "${APPLICATION_INI_FILE}"; then
			LineCharacters="$(run_script 'config_get' LineCharacters)"
		else
			LineCharacters="$(run_script 'config_get' LineCharacters "${DEFAULT_INI_FILE}")"
			run_script 'config_set' LineCharacters "${LineCharacters}"
		fi
	else
		if run_script 'env_var_exists' LineCharacters "${APPLICATION_INI_FILE}"; then
			Borders="$(run_script 'config_get' LineCharacters)"
		else
			Borders="$(run_script 'config_get' Borders "${DEFAULT_INI_FILE}")"
		fi
		run_script 'config_set' Borders "${Borders}"
		LineCharacters="$(run_script 'config_get' LineCharacters "${DEFAULT_INI_FILE}")"
		run_script 'config_set' LineCharacters "${LineCharacters}"
	fi

	# Set the dialog options based on the settings in the .ini file
	if is_true "${Borders}"; then
		if is_false "${LineCharacters}"; then
			DialogOptions+=" --ascii-lines"
		fi
	else
		DialogOptions+=" --no-lines"
	fi
	if is_true "${Scrollbar}"; then
		DialogOptions+=" --scrollbar"
	else
		DialogOptions+=" --no-scrollbar"
	fi
	if is_true "${Shadow}"; then
		DialogOptions+=" --shadow"
		DC["WindowColsAdjust"]=$((DC["WindowColsAdjust"] + 2))
		DC["WindowRowsAdjust"]=$((DC["WindowRowsAdjust"] + 1))
	else
		DialogOptions+=" --no-shadow"
	fi

	echo "${DialogOptions}" > "${DIALOG_OPTIONS_FILE}" ||
		fatal \
			"Failed to save dialog options file." \
			"Failing command: ${C["FailingCommand"]}echo \"${DialogOptions}\" > \"${DIALOG_OPTIONS_FILE}\""
	run_script 'set_permissions' "${DIALOG_OPTIONS_FILE}"

	cp "${DialogFile}" "${DIALOGRC}"
	run_script 'set_permissions' "${DIALOGRC}"

	run_script 'config_set' Theme "${ThemeName}"
}

test_config_theme() {
	warn "CI does not test config_theme."
}
