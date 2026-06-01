#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_options_display() {
	if [[ ${CI-} == true ]]; then
		return
	fi

	local Title="Display Options"

	run_script 'config_theme' &> /dev/null

	local DrawLineOption="Draw Lines"
	local ShowBordersOption="Show Borders"
	local ShowScrollbarOption="Show Scrollbars"
	local ShowShadowOption="Show Shadows"
	local LargeButtonsOption="Large Buttons"

	local -A OptionDescription OptionVariable

	OptionDescription["${DrawLineOption}"]="{{|ListDefault|}}Use line drawing characters"
	OptionDescription["${ShowBordersOption}"]="{{|ListDefault|}}Show borders in dialog boxes"
	OptionDescription["${ShowScrollbarOption}"]="{{|ListDefault|}}Show a scrollbar in dialog boxes"
	OptionDescription["${ShowShadowOption}"]="{{|ListDefault|}}Show a shadow under the dialog boxes"
	OptionDescription["${LargeButtonsOption}"]="{{|ListDefault|}}Use large buttons (Whiptail)"

	OptionVariable["${DrawLineOption}"]="ui.line_characters"
	OptionVariable["${ShowBordersOption}"]="ui.borders"
	OptionVariable["${ShowScrollbarOption}"]="ui.scrollbar"
	OptionVariable["${ShowShadowOption}"]="ui.shadow"
	OptionVariable["${LargeButtonsOption}"]="ui.large_buttons"

	while true; do
		local EnabledOptions=()
		local Opts=()
		for Option in "${DrawLineOption}" "${ShowBordersOption}" "${ShowScrollbarOption}" "${ShowShadowOption}" "${LargeButtonsOption}"; do
			local Value
			run_script 'config_get_into' Value "${OptionVariable["${Option}"]}" || true
			if is_true "${Value}"; then
				EnabledOptions+=("${Option}")
				Opts+=("${Option}" "${OptionDescription["${Option}"]}" ON)
			else
				Opts+=("${Option}" "${OptionDescription["${Option}"]}" OFF)
			fi
		done
		local -a ChoiceDialog=(
			"${Title}"
			"Choose the options to enable."
			--ok-label:Select
			--cancel-label:Back
			--exit-button
			--separate-output
			"${Opts[@]}"
		)
		local -a ChoicesArray=()
		local -i DialogButtonPressed=0
		tui_checklist_into_array ChoicesArray "${ChoiceDialog[@]}" || DialogButtonPressed=$?
		case ${DIALOG_BUTTONS[DialogButtonPressed]-} in
			OK)
				local -a OptionsToTurnOff OptionsToTurnOn
				readarray -t OptionsToTurnOff < <(
					printf '%s\n' "${EnabledOptions[@]}" "${ChoicesArray[@]}" "${ChoicesArray[@]}" | sort -f | uniq -u
				)
				readarray -t OptionsToTurnOn < <(
					printf '%s\n' "${EnabledOptions[@]}" "${EnabledOptions[@]}" "${ChoicesArray[@]}" | sort -f | uniq -u
				)
				if [[ -n ${OptionsToTurnOff[*]-} || ${OptionsToTurnOn[*]-} ]]; then
					if [[ -n ${OptionsToTurnOff[*]-} ]]; then
						for Option in "${OptionsToTurnOff[@]}"; do
							run_script 'config_set' "${OptionVariable["${Option}"]}" false
						done
					fi
					if [[ -n ${OptionsToTurnOn[*]-} ]]; then
						for Option in "${OptionsToTurnOn[@]}"; do
							run_script 'config_set' "${OptionVariable["${Option}"]}" true
						done
					fi
					run_script 'config_theme' &> /dev/null
				fi
				;;
			CANCEL | ESC)
				return
				;;
			EXIT)
				run_script 'menu_exit' || true
				;;
			*)
				invalid_tui_button ${DialogButtonPressed}
				;;
		esac
	done
}

test_menu_options_display() {
	warn "CI does not test menu_options_display."
}
