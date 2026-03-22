#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

# is_theme_file_path <Arg>
# Returns 0 if the argument looks like a file path rather than a theme name.
# file: prefix, bare .dstheme extension, or path separators all qualify.
# user: URIs are always treated as named themes, never as file paths.
is_theme_file_path() {
	local Arg=${1-}
	[[ ${Arg} == user:* ]] && return 1
	[[ ${Arg} == file:* ]] && return 0
	[[ ${Arg} == *"${THEME_FILE_EXT}" ]] && return 0
	[[ ${Arg} == */* ]] && return 0
	return 1
}

# resolve_theme_archive <ThemeNameOrURI> <OutVar>
# Sets OutVar to the path of the .dstheme archive for the given name or URI.
resolve_theme_archive() {
	local NameOrURI=${1-}
	local -n _OutVar=${2}
	if [[ ${NameOrURI} == file:* ]]; then
		_OutVar="${NameOrURI#file:}"
	elif [[ ${NameOrURI} == user:* ]]; then
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

	# If the argument looks like a file path, resolve it to an absolute file: URI.
	if [[ -n ${ThemeName-} ]] && is_theme_file_path "${ThemeName}"; then
		local FilePath="${ThemeName#file:}"
		FilePath="$(realpath -m "${FilePath}")"
		if [[ ! -f ${FilePath} ]]; then
			error "Theme file not found: '{{|File|}}${FilePath}{{[-]}}'"
			return 1
		fi
		ThemeName="file:${FilePath}"
	fi

	if [[ -z ${ThemeName-} ]]; then
		ThemeName="$(get_toml_val "${APPLICATION_TOML_FILE}" "ui.theme")"
		if ! run_script 'theme_exists' "${ThemeName}"; then
			# Only fall back to a default when there is no cached active theme to use.
			# If ACTIVE_THEME_FILE exists, ensure_theme_extracted will use it below.
			if [[ ! -f ${ACTIVE_THEME_FILE} ]]; then
				for Name in "${DefaultThemes[@]}"; do
					if run_script 'theme_exists' "${Name}"; then
						ThemeName="${Name}"
						break
					fi
				done
			fi
		fi
	fi

	local ThemeArchive
	resolve_theme_archive "${ThemeName}" ThemeArchive

	if ! ensure_theme_extracted "${ThemeArchive}"; then
		error "{{|ApplicationName|}}${APPLICATION_NAME}{{[-]}} theme '{{|Theme|}}${ThemeName}{{[-]}}' does not exist."
		return 1
	fi

	local ThemeFile="${EXTRACTED_THEME_FILE}"
	hrx_extract_file "${ACTIVE_THEME_FILE}" "${THEME_FILE_NAME}" "${ThemeFile}"
	hrx_extract_file "${ACTIVE_THEME_FILE}" "${DIALOGRC_NAME}" "${DIALOGRC}"
	run_script 'set_permissions' "${ThemeFile}"

	declare -Agx DC=()
	declare -Agx D=()

	D+=(
		["_defined_"]=1
	)
	D+=( # Dialog positioning adjustment values
		["WindowColsAdjust"]=4
		["WindowRowsAdjust"]=4
		["TextColsAdjust"]=4
		["TextRowsAdjust"]=5
	)

	local sem_p sem_s dir_p dir_s
	sem_p="$(get_toml_val "${ThemeFile}" "syntax.semantic_prefix")"
	[[ -z ${sem_p} ]] && sem_p="{{|"
	sem_s="$(get_toml_val "${ThemeFile}" "syntax.semantic_suffix")"
	[[ -z ${sem_s} ]] && sem_s="|}}"
	dir_p="$(get_toml_val "${ThemeFile}" "syntax.direct_prefix")"
	[[ -z ${dir_p} ]] && dir_p="{{["
	dir_s="$(get_toml_val "${ThemeFile}" "syntax.direct_suffix")"
	[[ -z ${dir_s} ]] && dir_s="]}}"

	local -a VarList
	readarray -t VarList < <(get_toml_section_key_list "${ThemeFile}" "colors")
	local VarName
	for VarName in "${VarList[@]-}"; do
		DC["${VarName}"]="$(get_toml_val "${ThemeFile}" "colors.${VarName}")"
	done
	local StyleName
	for StyleName in "${!DC[@]}"; do
		DC["${StyleName}"]="$(resolve_styles DC "${DC["${StyleName}"]}" "${sem_p}" "${sem_s}" "${dir_p}" "${dir_s}")"
	done

	D["ThemeName"]="$(get_toml_val "${ThemeFile}" "metadata.name")"
	local DialogOptions="--colors --output-fd 1 --cr-wrap --no-collapse"

	local LineCharacters Borders Scrollbar Shadow
	Borders="$(get_toml_val "${APPLICATION_TOML_FILE}" "ui.borders")"
	LineCharacters="$(get_toml_val "${APPLICATION_TOML_FILE}" "ui.line_characters")"
	Scrollbar="$(get_toml_val "${APPLICATION_TOML_FILE}" "ui.scrollbar")"
	Shadow="$(get_toml_val "${APPLICATION_TOML_FILE}" "ui.shadow")"

	D+=(
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
		D["WindowColsAdjust"]=$((D["WindowColsAdjust"] + 2))
		D["WindowRowsAdjust"]=$((D["WindowRowsAdjust"] + 1))
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
