#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

# resolve_theme_archive <ThemeNameOrURI> <OutVar>
# Sets OutVar to the path of the .dstheme archive for the given name or URI.
# Returns 1 if the name/URI format is unrecognised.
resolve_theme_archive() {
	local NameOrURI=${1-}
	local -n _OutVar=${2}
	if [[ ${NameOrURI} == user:* ]]; then
		_OutVar="${USER_THEMES_FOLDER}/${NameOrURI#user:}${THEME_FILE_EXT}"
	else
		_OutVar="${THEME_FOLDER}/${NameOrURI}${THEME_FILE_EXT}"
	fi
}

# ensure_theme_extracted <ThemeArchive>
# Copies the archive to ACTIVE_THEME_FILE when the content differs.
# If the source archive is missing but ACTIVE_THEME_FILE already exists,
# silently returns success (uses cached version).
ensure_theme_extracted() {
	local ThemeArchive=${1-}
	if [[ ! -f ${ThemeArchive} ]]; then
		# Source gone — use existing active theme file if available
		if [[ -f ${ACTIVE_THEME_FILE} ]]; then
			return 0
		fi
		return 1
	fi
	if ! cmp -s "${ThemeArchive}" "${ACTIVE_THEME_FILE}" 2> /dev/null; then
		cp "${ThemeArchive}" "${ACTIVE_THEME_FILE}"
		run_script 'set_permissions' "${ACTIVE_THEME_FILE}"
	fi
}

config_theme() {
	local ThemeName=${1-}

	local DefaultThemes=(
		"${APPLICATION_NAME}"
		Default
	)

	if [[ ! -f ${APPLICATION_TOML_FILE} ]]; then
		run_script 'config_create'
	fi

	if [[ -z ${ThemeName-} ]]; then
		ThemeName="$(get_toml_val "${APPLICATION_TOML_FILE}" "ui.theme")"
		if ! run_script 'theme_exists' "${ThemeName}"; then
			for Name in "${DefaultThemes[@]}"; do
				if run_script 'theme_exists' "${Name}"; then
					ThemeName="${Name}"
					break
				fi
			done
		fi
	fi

	local ThemeArchive
	resolve_theme_archive "${ThemeName}" ThemeArchive

	if ! ensure_theme_extracted "${ThemeArchive}"; then
		error "${C["ApplicationName"]-}${APPLICATION_NAME}${NC-} theme '${C["Theme"]}${ThemeName}${NC}' does not exist."
		return 1
	fi

	local ThemeFile="${EXTRACTED_THEME_FILE}"
	hrx_extract_file "${ACTIVE_THEME_FILE}" "${THEME_FILE_NAME}" "${ThemeFile}"
	hrx_extract_file "${ACTIVE_THEME_FILE}" "${DIALOGRC_NAME}" "${DIALOGRC}"
	run_script 'set_permissions' "${ThemeFile}"

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
	Borders="$(get_toml_val "${APPLICATION_TOML_FILE}" "ui.borders")"
	LineCharacters="$(get_toml_val "${APPLICATION_TOML_FILE}" "ui.line_characters")"
	Scrollbar="$(get_toml_val "${APPLICATION_TOML_FILE}" "ui.scrollbar")"
	Shadow="$(get_toml_val "${APPLICATION_TOML_FILE}" "ui.shadow")"

	DC+=(
		["Borders"]="${Borders}"
		["LineCharacters"]="${LineCharacters}"
		["Scrollbar"]="${Scrollbar}"
		["Shadow"]="${Shadow}"
	)

	# Set the dialog options based on the settings in the .toml file
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

	RunAndLog "" "cp:info" \
		fatal "Failed to save dialog options file." \
		cp <(printf "%s" "${DialogOptions}") "${DIALOG_OPTIONS_FILE}"
	run_script 'set_permissions' "${DIALOG_OPTIONS_FILE}"

	run_script 'set_permissions' "${DIALOGRC}"

	set_toml_val "${APPLICATION_TOML_FILE}" "ui.theme" "${ThemeName}"
}

test_config_theme() {
	warn "CI does not test config_theme."
}
