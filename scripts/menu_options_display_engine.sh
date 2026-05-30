#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_options_display_engine() {
	if [[ ${CI-} == true ]]; then
		return
	fi

	local Title="Choose Display Engine"

	local DialogOption="Dialog"
	local WhiptailOption="Whiptail"

	local -A OptionDescription=(
		["${DialogOption}"]="{{|ListDefault|}}Use the modern Dialog command"
		["${WhiptailOption}"]="{{|ListDefault|}}Use the legacy Whiptail command"
	)
	local -A OptionValue=(
		["${DialogOption}"]="dialog"
		["${WhiptailOption}"]="whiptail"
	)

	local CurrentOption
	run_script 'config_get_into' CurrentOption ui.display_engine || true

	while true; do
		local -a Opts=()
		for Tag in "${DialogOption}" "${WhiptailOption}"; do
			if [[ ${OptionValue["${Tag}"]} == "${CurrentOption}" ]]; then
				Opts+=("${Tag}" "${OptionDescription["${Tag}"]}" ON "")
			else
				Opts+=("${Tag}" "${OptionDescription["${Tag}"]}" OFF "")
			fi
		done
		local -a ChoiceDialog=(
			"${Title}"
			"Select the display engine to use."
			--item-help
			--ok-label:Select
			--cancel-label:Back
			--exit-button
			--default-item:"${LastChoice}"
			"${Opts[@]}"
		)
		local Choice
		local -i DialogButtonPressed=0
		Choice=$(tui_radiolist "${ChoiceDialog[@]}") || DialogButtonPressed=$?
		LastChoice=${Choice}
		case ${DIALOG_BUTTONS[DialogButtonPressed]-} in
			OK)
				if [[ ${OptionValue["${Choice}"]} != "${CurrentOption}" ]]; then
					CurrentOption=${OptionValue["${Choice}"]}
					run_script 'config_display_engine' "${CurrentOption}" &> /dev/null
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

test_menu_options_display_engine() {
	warn "CI does not test menu_options_display_engine."
}
