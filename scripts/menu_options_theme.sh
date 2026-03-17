#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_options_theme() {
	if [[ ${CI-} == true ]]; then
		return
	fi

	local Title="Choose Theme"

	run_script 'config_theme'

	local CurrentTheme
	CurrentTheme="$(run_script 'theme_name')"

	# Build parallel arrays from structured theme_list output (DisplayName|ConfigValue|IsUserTheme)
	local -a DisplayNames=() ConfigValues=() IsUserTheme=()
	local -A ThemeDescription ThemeAuthor
	while IFS='|' read -r DisplayName ConfigValue UserTheme; do
		DisplayNames+=("${DisplayName}")
		ConfigValues+=("${ConfigValue}")
		IsUserTheme+=("${UserTheme}")
		ThemeDescription["${ConfigValue}"]="$(run_script 'theme_description' "${ConfigValue}")"
		ThemeAuthor["${ConfigValue}"]="$(run_script 'theme_author' "${ConfigValue}")"
	done < <(run_script 'theme_list')

	# Check if the configured theme appears in the list; if not, prepend an orphaned placeholder
	local FoundCurrent=false
	for ConfigValue in "${ConfigValues[@]-}"; do
		if [[ ${ConfigValue} == "${CurrentTheme}" ]]; then
			FoundCurrent=true
			break
		fi
	done
	if [[ ${FoundCurrent} == false && -n ${CurrentTheme} ]]; then
		local OrphanDisplay="(missing) ${CurrentTheme}"
		DisplayNames=("${OrphanDisplay}" "${DisplayNames[@]-}")
		ConfigValues=("${CurrentTheme}" "${ConfigValues[@]-}")
		IsUserTheme=("true" "${IsUserTheme[@]-}")
		ThemeDescription["${CurrentTheme}"]="Source file not found — using cached version"
		ThemeAuthor["${CurrentTheme}"]=""
	fi

	local LastChoice="${CurrentTheme}"
	while true; do
		local -a Opts=()
		local -i i=0
		for i in "${!ConfigValues[@]}"; do
			local ConfigValue="${ConfigValues[${i}]}"
			local DisplayName="${DisplayNames[${i}]}"
			local ItemText="${ThemeDescription["${ConfigValue}"]-}"
			if [[ -n ${ThemeAuthor["${ConfigValue}"]-} ]]; then
				ItemText+=" [by ${ThemeAuthor["${ConfigValue}"]}]"
			fi
			# Prefix description with user-theme colour if applicable
			if [[ ${IsUserTheme[${i}]} == true ]]; then
				ItemText="${DC["ListAppUserDefined"]-}${ItemText}"
			else
				ItemText="${DC["ListApp"]-}${ItemText}"
			fi
			if [[ ${ConfigValue} == "${CurrentTheme}" ]]; then
				Opts+=("${ConfigValue}" "${DisplayName} — ${ItemText}" ON)
			else
				Opts+=("${ConfigValue}" "${DisplayName} — ${ItemText}" OFF)
			fi
		done
		local -a ChoiceDialog=(
			--output-fd 1
			--title "${DC["Title"]-}${Title}"
			--ok-label "Select"
			--cancel-label "Back"
			--radiolist "Select the theme to apply." 0 0 0
			"${Opts[@]}"
		)
		local Choice
		local -i DialogButtonPressed=0
		Choice=$(_dialog_ --default-item "${LastChoice}" "${ChoiceDialog[@]}") || DialogButtonPressed=$?
		LastChoice=${Choice}
		case ${DIALOG_BUTTONS[DialogButtonPressed]-} in
			OK)
				CurrentTheme="${Choice}"
				if run_script 'config_theme' "${CurrentTheme}"; then
					run_script 'menu_dialog_example' "Applied theme ${CurrentTheme}" "${APPLICATION_COMMAND} --theme \"${CurrentTheme}\""
				else
					dialog_error "${Title}" "Unable to apply theme ${CurrentTheme}"
				fi
				;;
			CANCEL | ESC)
				return
				;;
			*)
				invalid_dialog_button ${DialogButtonPressed}
				;;
		esac
	done
}

test_menu_options_theme() {
	warn "CI does not test menu_options_theme."
}
