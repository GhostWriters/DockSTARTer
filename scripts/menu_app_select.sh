#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=(
	column
	dialog
	sed
)

declare -A StatusText=(
	["_Waiting_"]="  Waiting  "
	["_InProgress_"]="In Progress"
	["_Completed_"]=" Completed "
)

declare -A StatusHighlight=(
	["_Waiting_"]="{{|ProgressWaiting|}}"
	["_InProgress_"]="{{|ProgressInProgress|}}"
	["_Completed_"]="{{|ProgressCompleted|}}"
)

declare Title="Select Applications"
declare DialogGaugeText FullDialogGaugeText ExpandedDialogGaugeText
declare -i ProgressSteps ProgressStepNumber

declare GaugePipe ProgressLog
declare -i GaugePipe_fd ProgressLog_fd
declare Dialog_PID

menu_app_select() {
	local -a ProcessInfo

	local FindAddedApps='Detecting installed applications'
	local FindBuiltinApps='Detecting built in applications'
	local ProcessAppList='Processing application list to create menu'
	local AddApps='Adding applications'
	local RemoveApps='Removing applications'
	local UpdateVars='Updating variable files'

	ProcessInfo=(
		"${FindAddedApps}" "" ""
		"${FindBuiltinApps}" "" ""
		"${ProcessAppList}" "" ""
	)

	init_gauge "${Title}" "${ProcessInfo[@]}"
	{
		ProgressSteps=4
		ProgressStepNumber=0
		update_gauge 0 "${FindAddedApps}" "_Waiting_" "_InProgress_"

		local -a AppList AddedApps BuiltinApps
		local AddedAppsRegex=''

		readarray -t AddedApps < <(run_script 'app_list_added')
		update_gauge 1

		readarray -t AddedApps < <(run_script 'app_filter_runnable' "${AddedApps[@]-}" | sort -f -u)
		update_gauge 1

		readarray -t AddedApps < <(run_script 'app_nicename_from_template' "${AddedApps[@]-}")
		update_gauge 1

		if [[ -n ${AddedApps[*]-} ]]; then
			local old_IFS="${IFS}"
			IFS='|'
			AddedAppsRegex="${AddedApps[*]}"
			IFS="${old_IFS}"

			set_screen_size
			printf "\nCurrently installed applications:\n\n"
			local -i TextCols
			TextCols=$((COLUMNS - D["WindowColsAdjust"] - D["TextColsAdjust"]))
			local Indent='   '
			local -a AddedAppsTable
			readarray -t AddedAppsTable < <(printf "%s\n" "${AddedApps[@]}")
			readarray -t AddedAppsTable < <(
				printf "%s\n" "${AddedAppsTable[@]}" |
					column -c "$((TextCols - ${#Indent}))" |
					expand |
					indent_string_pipe "${#Indent}"
			)
		fi
		update_gauge 1

		printf "%s\n" "${AddedAppsTable[@]}"
		update_gauge 0 "${FindAddedApps}" "_InProgress_" "_Completed_"

		ProgressSteps=4
		ProgressStepNumber=0
		update_gauge 0 "${FindBuiltinApps}" "_Waiting_" "_InProgress_"

		readarray -t BuiltinApps < <(run_script 'app_list_nondeprecated')
		update_gauge 1

		readarray -t BuiltinApps < <(run_script 'app_filter_runnable' "${BuiltinApps[@]}")
		update_gauge 1

		readarray -t BuiltinApps < <(run_script 'app_nicename_from_template' "${BuiltinApps[@]}")
		update_gauge 1

		local -a AllApps
		readarray -t AllApps < <(
			printf '%s\n' "${AddedApps[@]}" "${BuiltinApps[@]}" |
				sort -f -u
		)
		update_gauge 1

		update_gauge 0 "${FindBuiltinApps}" "_InProgress_" "_Completed_"

		local -i AppCount=${#AllApps[@]}
		ProgressSteps=${AppCount}
		ProgressStepNumber=0
		update_gauge 0 "${ProcessAppList}" "_Waiting_" "_InProgress_"

		local LastAppLetter=''
		for AppName in "${AllApps[@]}"; do
			local AppLetter=${AppName:0:1}
			AppLetter=${AppLetter^^}
			if [[ -n ${LastAppLetter-} && ${LastAppLetter} != "${AppLetter}" ]]; then
				AppList+=("" "" "off")
			fi
			LastAppLetter=${AppLetter}
			update_gauge 1 "${ProcessAppList}" "_InProgress_" "_InProgress_" "${AppName}"
			local AppDescription
			AppDescription=$(run_script 'app_description_from_template' "${AppName}")
			local AppColor="{{|ListApp|}}"
			if [[ -n $(run_script 'appname_to_instancename' "${AppName}") ]]; then
				AppColor="{{|ListAppUserDefined|}}"
			fi
			if [[ ${AppName} =~ ^(${AddedAppsRegex})$ ]]; then
				AppList+=("${AppName}" "${AppColor}${AppDescription}" "on")
			else
				AppList+=("${AppName}" "${AppColor}${AppDescription}" "off")
			fi
		done
		update_gauge 0 "${ProcessAppList}" "_InProgress_" "_Completed_"
		sleep "${DIALOGTIMEOUT}"
	} &> "${ProgressLog}"
	close_gauge

	local -i SelectedAppsDialogButtonPressed
	local SelectedApps
	if [[ ${CI-} == true ]]; then
		SelectedAppsDialogButtonPressed=${DIALOG_CANCEL}
	else
		set_screen_size
		local SelectAppsDialogText="{{[-]}}Choose which apps you would like to install:\n Use {{|KeyCap|}}[up]{{[-]}}, {{|KeyCap|}}[down]{{[-]}}, and {{|KeyCap|}}[space]{{[-]}} to select apps, and {{|KeyCap|}}[tab]{{[-]}} to switch to the buttons at the bottom."
		local -a SelectedAppsDialog=(
			"${Title}"
			"${SelectAppsDialogText}"
			--maximized
			--ok-label:Done
			--cancel-label:Cancel
			--separate-output
			"${AppList[@]}"
		)
		SelectedAppsDialogButtonPressed=0
		SelectedApps=$(dialog_checklist "${SelectedAppsDialog[@]}") || SelectedAppsDialogButtonPressed=$?
	fi
	case ${DIALOG_BUTTONS[SelectedAppsDialogButtonPressed]-} in
		OK)
			local -a AppsToAdd AppsToRemove
			local RemoveCommand="${APPLICATION_COMMAND} --remove"
			local AddCommand="${APPLICATION_COMMAND} --add"
			readarray -t AppsToRemove < <(
				printf '%s\n' "${AddedApps[@]}" "${SelectedApps[@]}" "${SelectedApps[@]}" |
					sort -f |
					uniq -u
			)
			readarray -t AppsToAdd < <(
				printf '%s\n' "${AddedApps[@]}" "${AddedApps[@]}" "${SelectedApps[@]}" |
					sort -f |
					uniq -u
			)
			if [[ -n ${AppsToAdd[*]-} || -n ${AppsToRemove[*]-} ]]; then
				ProgressInfo=()
				if [[ -n ${AppsToRemove[*]-} ]]; then
					ProgressInfo+=(
						"Removing applications" "${RemoveCommand}" "${AppsToRemove[*]}"
						"" "" ""
					)
				fi
				if [[ -n ${AppsToAdd[*]-} ]]; then
					ProgressInfo+=(
						"Adding applications" "${AddCommand}" "${AppsToAdd[*]}"
						"" "" ""
					)
				fi
				ProgressInfo+=("${UpdateVars}" "" "")
				ProgressSteps=0
				init_gauge "Enabling Selected Applications" "${ProgressInfo[@]}"
				{
					run_script 'env_backup'
					if [[ -n ${AppsToRemove[*]-} ]]; then
						ProgressSteps=${#AppsToRemove[@]}
						ProgressStepNumber=0
						update_gauge 0 "${RemoveApps}" "_Waiting_" "_InProgress_"
						update_gauge 0 "${RemoveCommand}" "_Waiting_" "_InProgress_"
						notice "Removing variables for deselected apps."
						for AppName in "${AppsToRemove[@]}"; do
							update_gauge 0 "${AppName}" "_Waiting_" "_InProgress_"
							run_script 'appvars_purge' "${AppName}"
							update_gauge 1 "${AppName}" "_InProgress_" "_Completed_"
						done
						update_gauge 0 "${RemoveCommand}" "_InProgress_" "_Completed_"
						update_gauge 0 "${RemoveApps}" "_InProgress_" "_Completed_"
					fi
					if [[ -n ${AppsToAdd[*]-} ]]; then
						ProgressSteps=${#AppsToAdd[@]}
						ProgressStepNumber=0
						update_gauge 0 "${AddApps}" "_Waiting_" "_InProgress_"
						update_gauge 0 "${AddCommand}" "_Waiting_" "_InProgress_"
						notice "Creating variables for selected apps."
						for AppName in "${AppsToAdd[@]}"; do
							update_gauge 0 "${AppName}" "_Waiting_" "_InProgress_"
							run_script 'appvars_create' "${AppName}"
							run_script 'appvars_sanitize' "${AppName}"
							update_gauge 1 "${AppName}" "_InProgress_" "_Completed_"
						done
						update_gauge 0 "${AddCommand}" "_InProgress_" "_Completed_"
						update_gauge 0 "${AddApps}" "_InProgress_" "_Completed_"
					fi
					ProgressSteps=1
					ProgressStepNumber=0
					update_gauge 0 "${UpdateVars}" "_Waiting_" "_InProgress_"
					notice "Updating variable files"
					run_script 'env_update'
					update_gauge 1 "${UpdateVars}" "_InProgress_" "_Completed_"
				} &> "${ProgressLog}"
			fi
			sleep "${DIALOGTIMEOUT}"
			close_gauge
			return 0
			;;
		CANCEL | ESC)
			return 1
			;;
		*)
			invalid_dialog_button ${SelectedAppsDialogButtonPressed}
			;;
	esac
}

show_gauge() {
	local GaugeTitle="${1-${Title}}"

	_dialog_backtitle_
	local -a GlobalDialogOptions=(
		--file "${DIALOG_OPTIONS_FILE}"
		--backtitle "${BACKTITLE}"
	)

	set_screen_size
	local -i ScreenRows=${LINES}
	local -i ScreenCols=${COLUMNS}
	local -i DialogCols
	#local -i DialogRows

	local -i GaugeDialogStartRow
	local -i LogDialogStartRow
	local -i DialogStartCol

	local -i GaugeDialogRows
	local -i LogDialogRows

	local -i GaugeDialogTextRows

	GaugeDialogStartRow=2
	DialogStartCol=2

	#DialogRows=$((ScreenRows - D["WindowRowsAdjust"]))
	DialogCols=$((ScreenCols - D["WindowColsAdjust"]))

	GaugeDialogTextRows=$(wc -l <<< "${FullDialogGaugeText}")
	GaugeDialogRows=$((GaugeDialogTextRows + D["TextRowsAdjust"]))

	LogDialogStartRow="$((GaugeDialogStartRow + GaugeDialogRows + (D["WindowRowsAdjust"] - 3)))"
	LogDialogRows="$((ScreenRows - LogDialogStartRow - (D["WindowRowsAdjust"] - 3) - 1))"

	# Create the pipes to communicate with the gauge and log dialog windows
	GaugePipe=$(mktemp -u -t "${APPLICATION_NAME}.${FUNCNAME[0]}.GaugePipe.XXXXXXXXXX")
	mkfifo "${GaugePipe}"
	exec {GaugePipe_fd}<> "${GaugePipe}"
	ProgressLog=$(mktemp -t "${APPLICATION_NAME}.${FUNCNAME[0]}.ProgressLog.XXXXXXXXXX")
	exec {ProgressLog_fd}<> "${ProgressLog}"

	local -a GaugeDialog=(
		"${GlobalDialogOptions[@]}"
		--title "{{|TitleSuccess|}}${GaugeTitle}"
		--begin "${GaugeDialogStartRow}" "${DialogStartCol}"
		--gauge "${ExpandedDialogGaugeText}"
		"${GaugeDialogRows}" "${DialogCols}"
		0
	)
	local -a LogDialog=(
		"${GlobalDialogOptions[@]}"
		--title "{{|Title|}}Log Output"
		--begin "${LogDialogStartRow}" "${DialogStartCol}"
		--keep-window
		--tailboxbg "${ProgressLog}"
		"${LogDialogRows}" "${DialogCols}"
	)
	local DialogOptions=(
		"${LogDialog[@]}"
		--and-widget
		"${GaugeDialog[@]}"
	)

	# Start the gauge and progress dialog windows in the background, and get the process id
	local index
	for index in "${!DialogOptions[@]}"; do
		DialogOptions["${index}"]=$(resolve_styles DC "${DialogOptions["${index}"]}")
	done
	"${DIALOG}" "${DialogOptions[@]}" < "${GaugePipe}" &
	Dialog_PID=$!
}

close_gauge() {
	# Signal the dialog gauge and progress windows to terminate
	kill -SIGTERM "${Dialog_PID}" &> /dev/null || true
	wait "${Dialog_PID}" &> /dev/null || true
	# Remove the communication pipes to dialog
	exec {GaugePipe_fd}>&- &> /dev/null || true
	rm "${GaugePipe}" &> /dev/null || true
	exec {ProgressLog_fd}>&- &> /dev/null || true
	rm "${ProgressLog}" &> /dev/null || true
}

init_gauge_text() {
	set_screen_size
	local IndentCols=3
	local SpaceCols=1
	local Indent Space
	Indent="$(printf "%${IndentCols}s" '')"
	Space="$(printf "%${SpaceCols}s" '')"
	local WaitingHighlight=${StatusHighlight["_Waiting_"]}
	local WaitingText=${StatusText["_Waiting_"]}
	local -i HeadingCols=0
	local -a HeadingText Command AppNames
	while [[ $# -gt 0 ]]; do
		HeadingText+=("${1-}")
		Command+=("${2-}")
		AppNames+=("${3-}")
		if [[ ${#HeadingText[-1]} -gt HeadingCols ]]; then
			HeadingCols=${#HeadingText[-1]}
		fi
		shift 3 || true
	done
	DialogGaugeText=''
	for index in "${!HeadingText[@]}"; do
		if [[ -z "${HeadingText[index]}${Command[index]}${AppNames[index]}" ]]; then
			DialogGaugeText+="\n"
			continue
		fi
		if [[ -n ${HeadingText[index]} ]]; then
			local -i HeadingPadCols
			HeadingPadCols=$((HeadingCols - ${#HeadingText[index]}))
			local HeadingPad
			HeadingPad="$(printf "%${HeadingPadCols}s" '')"
			DialogGaugeText+="${WaitingHighlight}${HeadingText[index]}{{[-]}}${HeadingPad} ${WaitingHighlight}[${WaitingText}]{{[-]}}\n"
		fi
		if [[ -n ${Command[index]} ]]; then
			local -i CommandCols=${#Command[index]}
			local -i TextCols
			AppsColumnStart=$((IndentCols + CommandCols + SpaceCols))
			TextCols=$((COLUMNS - D["WindowColsAdjust"] - D["TextColsAdjust"]))
			local -a AppNamesArray
			readarray -t AppNamesArray < <(xargs -n 1 <<< "${AppNames[index]}")

			local FormattedAppNames
			FormattedAppNames="$(
				printf "%s\n" "${AppNamesArray[@]}" |
					wordwrap_pipe "$((TextCols - AppsColumnStart))" |
					expand |
					indent_string_pipe "${AppsColumnStart}"
			)"

			# Get the color codes to add to the app names
			local BeginHighlight="${WaitingHighlight}"
			local EndHighlight="{{[-]}}"
			# Escape the backslahes to be used in sed
			BeginHighlight="${BeginHighlight//\\/\\\\}"
			EndHighlight="${EndHighlight//\\/\\\\}"

			# Highlight each app name
			FormattedAppNames="$(${SED} -E "s/\<([A-Za-z0-9_]+)\>/${BeginHighlight}\1${EndHighlight}/g" <<< "${FormattedAppNames}")"

			# Add the command name to the first line
			DialogGaugeText+="${Indent}${WaitingHighlight}${Command[index]}{{[-]}}${Space}${FormattedAppNames:AppsColumnStart}\n"
		fi
		#DialogGaugeText+="\n"
	done
	DialogGaugeText="$(printf '%b' "${DialogGaugeText}" | expand)"
	FullDialogGaugeText="${DialogGaugeText}"
	ExpandedDialogGaugeText="$(resolve_styles DC "${DialogGaugeText}")"
}

init_gauge() {
	local Title=${1-}
	shift || true
	init_gauge_text "$@"
	show_gauge "${Title}"
}

update_gauge_text() {
	# 1. Save and enable extglob locally
	local extglob_on=0
	shopt -q extglob || extglob_on=$?
	shopt -s extglob

	local SearchItem="${1-}"
	local OldStatus="${2-}"
	local NewStatus="${3-}"
	local NewStatusTag="${4:-$NewStatus}"

	# Resolve Status Tags
	if [[ ${NewStatusTag} =~ _Waiting_|_InProgress_|_Completed_ ]]; then
		NewStatusTag="${StatusText["${NewStatusTag}"]}"
	fi

	# Validation check
	if [[ -n ${SearchItem} && -n ${OldStatus} && -n ${StatusHighlight["$OldStatus"]} ]]; then
		local OldHighlight="${StatusHighlight["$OldStatus"]}"
		local NewHighlight="${StatusHighlight["$NewStatus"]}"
		local EndHighlight="{{[-]}}"

		local OldString="${OldHighlight}${SearchItem}${EndHighlight}"
		local NewString="${NewHighlight}${SearchItem}${EndHighlight}"

		local NewStatusString="${NewHighlight}[${NewStatusTag}]${EndHighlight}"

		# --- THE 6-STEP EXPANSION ---
		# Use quoted "$OldString" to treat your highlight tags as literal text
		local prefix="${DialogGaugeText%"${OldString}"*}"
		local target_and_suffix="${DialogGaugeText#"$prefix"}"
		local target_line="${target_and_suffix%%$'\n'*}"
		local suffix="${target_and_suffix#"$target_line"}"

		# Perform the swaps on the isolated line
		if [[ -n ${target_line} ]]; then
			# 1. Update the status box (e.g., [Waiting] -> [Completed])
			# By fully quoting "$OldHighlight" and "$EndHighlight", Bash treats them literally
			# while allowing the unquoted \[+([^\]])\] pattern to act as an extglob match!
			target_line="${target_line/%"$OldHighlight"\[+([^\]])\]"$EndHighlight"/$NewStatusString}"
			# 2. Update the name/highlight at the start of the line (Literal match)
			target_line="${target_line/"$OldString"/"$NewString"}"
		fi

		# Reassemble
		DialogGaugeText="${prefix}${target_line}${suffix}"
		FullDialogGaugeText="${DialogGaugeText}"
		ExpandedDialogGaugeText="$(resolve_styles DC "${DialogGaugeText}")"
	fi

	# 2. Restore original shell state
	[[ ${extglob_on} -ne 0 ]] && shopt -u extglob || true
}

update_gauge_percent_value() {
	local -i AddStep=${1-0}
	ProgressStepNumber+=${AddStep}
	if [[ ProgressSteps -gt 0 ]]; then
		ProgressPercent=$((100 * ProgressStepNumber / ProgressSteps))
		if [[ ProgressPercent -gt 100 ]]; then
			ProgressPercent=100
		fi
	else
		ProgressPercent=0
	fi
}

update_gauge_percent() {
	update_gauge_percent_value "${1-0}"
	echo "${ProgressPercent}" > "${GaugePipe}"
}

update_gauge() {
	update_gauge_percent_value "${1-0}"
	shift 1 || true
	if [[ $# -gt 0 ]]; then
		update_gauge_text "$@"
	fi
	printf 'XXX\n%s\n%s\nXXX\n' "${ProgressPercent}" "${ExpandedDialogGaugeText}" > "${GaugePipe}"
}

test_menu_app_select() {
	# run_script 'menu_app_select'
	warn "CI does not test menu_app_select."
}
