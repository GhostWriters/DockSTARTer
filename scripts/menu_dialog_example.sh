#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_dialog_example() {
	local Message=${1-}
	local CommandLine=${2-}

	local ThemeName ThemeDescription ThemeAuthor
	ThemeName="$(run_script 'theme_name')"
	ThemeDescription="$(run_script 'theme_description' "${ThemeName}")"
	ThemeAuthor="$(run_script 'theme_author' "${ThemeName}")"

	if [[ -z ${Message} ]]; then
		Message="Applied theme ${ThemeName}"
	fi
	if [[ -z ${CommandLine} ]]; then
		CommandLine="${APPLICATION_COMMAND} --theme"
	fi

	local Title=''
	for TitleStyle in Title TitleSuccess TitleWarning TitleError TitleQuestion; do
		if [[ -n ${Title-} ]]; then
			Title+=' '
		fi
		Title+="{{|${TitleStyle}|}}${TitleStyle}{{[-]}}"
	done

	local DialogText=''
	DialogText+="{{|Subtitle|}}${Message} and displaying sample{{[-]}}\n"
	DialogText+="  {{|CommandLine|}}${CommandLine}{{[-]}}\n"
	DialogText+="\n"
	DialogText+="        Theme: {{|Heading|}}${ThemeName}{{[-]}}\n"
	DialogText+="               {{|HeadingAppDescription|}}${ThemeDescription}{{[-]}}\n"
	DialogText+="\n"
	DialogText+=" Theme Author: {{|Heading|}}${ThemeAuthor}{{[-]}}\n"
	DialogText+="\n"
	DialogText+="Final Heading: {{|HeadingValue|}}AppName{{[-]}}"
	DialogText+=" {{|HeadingTag|}}[*HeadingTag*]{{[-]}} {{|HeadingTag|}}(HeadingTag){{[-]}}\n"
	DialogText+="\n"
	DialogText+="     Key Caps: {{|KeyCap|}}[up]{{[-]}} {{|KeyCap|}}[down]{{[-]}} {{|KeyCap|}}[left]{{[-]}} {{|KeyCap|}}[right]{{[-]}}\n"
	DialogText+="\n"
	DialogText+="Normal text\n"
	DialogText+="{{|Highlight|}}Highlighted text{{[-]}}\n"

	local Helpline="This is a sample help line with {{|Highlight|}}highlighted{{[-]}} text."

	set_screen_size
	local -a DialogOptions=(
		"" "" "${Helpline}"
		"BuiltInApp" "Built In App Description" "${Helpline}"
		"UserDefinedApp" "{{|ListAppUserDefined|}}User Defined App Description" "${Helpline}"
		"" "" "${Helpline}"
		"Variable File Heading" "{{|LineHeading|}}*** ${COMPOSE_ENV} ***" "${Helpline}"
		"Variable File Comment" "{{|LineComment|}}### A comment in the variable file" "${Helpline}"
		"Variable File Other" "{{|LineOther|}}Any other line in the file" "${Helpline}"
		"Variable File Variable" "{{|LineVar|}}VarName='Default Value'" "${Helpline}"
		"Variable File Mofified" "{{|ModifiedText|}}VarName='Modified Value'" "${Helpline}"
		"Variable File Add" "{{|LineAddVariable|}}<ADD VARIABLE>" "${Helpline}"
		"" "" "${Helpline}"
		"" "" "${Helpline}"
		"" "" "${Helpline}"
		"" "" "${Helpline}"
		"" "" "${Helpline}"
		"" "" "${Helpline}"
		"" "" "${Helpline}"
		"" "" "${Helpline}"
		"" "" "${Helpline}"
		"" "" "${Helpline}"
	)
	local -a MenuDialog=(
		"${Title}"
		"${DialogText}"
		--maximized
		--item-help
		"--ok-label:Select"
		"--cancel-label:Done"
		"${DialogOptions[@]}"
	)

	dialog_menu "${MenuDialog[@]}" > /dev/null || true
}

test_menu_dialog_example() {
	warn "CI does not test theme_exists."
}
