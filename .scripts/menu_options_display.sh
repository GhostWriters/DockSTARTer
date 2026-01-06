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

	local -A OptionDescription OptionVariable

	OptionDescription["${DrawLineOption}"]="${DC["ListDefault"]}Use line drawing characters"
	OptionDescription["${ShowBordersOption}"]="${DC["ListDefault"]}Show borders in dialog boxes"
	OptionDescription["${ShowScrollbarOption}"]="${DC["ListDefault"]}Show a scrollbar in dialog boxes"
	OptionDescription["${ShowShadowOption}"]="${DC["ListDefault"]}Show a shadow under the dialog boxes"

	OptionVariable["${DrawLineOption}"]="LineCharacters"
	OptionVariable["${ShowBordersOption}"]="Borders"
	OptionVariable["${ShowScrollbarOption}"]="Scrollbar"
	OptionVariable["${ShowShadowOption}"]="Shadow"

	while true; do
		local EnabledOptions=()
		local Opts=()
		for Option in "${DrawLineOption}" "${ShowBordersOption}" "${ShowScrollbarOption}" "${ShowShadowOption}"; do
			local Value
			Value="$(run_script 'config_get' "${OptionVariable["${Option}"]}")"
			if is_true "${Value}"; then
				EnabledOptions+=("${Option}")
				Opts+=("${Option}" "${OptionDescription["${Option}"]}" ON)
			else
				Opts+=("${Option}" "${OptionDescription["${Option}"]}" OFF)
			fi
		done
		local -a ChoiceDialog=(
			--output-fd 1
			--title "${DC["Title"]-}${Title}"
			--ok-label "Select"
			--cancel-label "Back"
			--separate-output
			--checklist "Choose the options to enable." 0 0 0
			"${Opts[@]}"
		)
		local Choices
		local -i DialogButtonPressed=0
		Choices=$(_dialog_ "${ChoiceDialog[@]}") || DialogButtonPressed=$?
		case ${DIALOG_BUTTONS[DialogButtonPressed]-} in
			OK)
				local -a ChoicesArray OptionsToTurnOff OptionsToTurnOn
				readarray -t ChoicesArray <<< "${Choices}"
				readarray -t OptionsToTurnOff < <(
					printf '%s\n' "${EnabledOptions[@]}" "${ChoicesArray[@]}" "${ChoicesArray[@]}" | sort -f | uniq -u
				)
				readarray -t OptionsToTurnOn < <(
					printf '%s\n' "${EnabledOptions[@]}" "${EnabledOptions[@]}" "${ChoicesArray[@]}" | sort -f | uniq -u
				)
				if [[ -n ${OptionsToTurnOff[*]-} || ${OptionsToTurnOn[*]-} ]]; then
					if [[ -n ${OptionsToTurnOff[*]-} ]]; then
						for Option in "${OptionsToTurnOff[@]}"; do
							run_script 'config_set' "${OptionVariable["${Option}"]}" OFF
						done
					fi
					if [[ -n ${OptionsToTurnOn[*]-} ]]; then
						for Option in "${OptionsToTurnOn[@]}"; do
							run_script 'config_set' "${OptionVariable["${Option}"]}" ON
						done
					fi
					run_script 'config_theme' &> /dev/null
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

test_menu_options_display() {
	warn "CI does not test menu_options_display."
}
