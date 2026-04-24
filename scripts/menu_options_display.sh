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

	OptionDescription["${DrawLineOption}"]="{{|ListDefault|}}Use line drawing characters"
	OptionDescription["${ShowBordersOption}"]="{{|ListDefault|}}Show borders in dialog boxes"
	OptionDescription["${ShowScrollbarOption}"]="{{|ListDefault|}}Show a scrollbar in dialog boxes"
	OptionDescription["${ShowShadowOption}"]="{{|ListDefault|}}Show a shadow under the dialog boxes"

	OptionVariable["${DrawLineOption}"]="line_characters"
	OptionVariable["${ShowBordersOption}"]="borders"
	OptionVariable["${ShowScrollbarOption}"]="scrollbar"
	OptionVariable["${ShowShadowOption}"]="shadow"

	while true; do
		local EnabledOptions=()
		local Opts=()
		for Option in "${DrawLineOption}" "${ShowBordersOption}" "${ShowScrollbarOption}" "${ShowShadowOption}"; do
			local Value
			Value="$(get_toml_val_bool "${APPLICATION_TOML_FILE}" "ui.${OptionVariable["${Option}"]}")"
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
			--extra-label:Back
			--cancel-label:Exit
			--separate-output
			"${Opts[@]}"
		)
		local Choices
		local -i DialogButtonPressed=0
		Choices=$(dialog_checklist "${ChoiceDialog[@]}") || DialogButtonPressed=$?
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
							set_toml_val_bool "${APPLICATION_TOML_FILE}" "ui.${OptionVariable["${Option}"]}" "false"
						done
					fi
					if [[ -n ${OptionsToTurnOn[*]-} ]]; then
						for Option in "${OptionsToTurnOn[@]}"; do
							set_toml_val_bool "${APPLICATION_TOML_FILE}" "ui.${OptionVariable["${Option}"]}" "true"
						done
					fi
					run_script 'config_theme' &> /dev/null
				fi
				;;
			EXTRA | ESC)
				return
				;;
			CANCEL)
				run_script 'menu_exit' || true
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
