#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -gx DIALOG
DIALOG=$(command -v dialog) || true

declare -Agx DC
declare -Agx D

declare -rgx DIALOGRC_NAME='.dialogrc'
declare -rgx DIALOG_OPTIONS_NAME='.dialogoptions'

declare -rgx DIALOGRC="${TEMP_FOLDER}/${DIALOGRC_NAME}"
declare -rgx DIALOG_OPTIONS_FILE="${TEMP_FOLDER}/${DIALOG_OPTIONS_NAME}"

declare -rigx DIALOGTIMEOUT=3
declare -rigx DIALOG_OK=0
declare -rigx DIALOG_CANCEL=1
declare -rigx DIALOG_HELP=2
declare -rigx DIALOG_EXTRA=3
declare -rigx DIALOG_ITEM_HELP=4
declare -rigx DIALOG_ERROR=254
declare -rigx DIALOG_ESC=255
declare -ragx DIALOG_BUTTONS=(
	[DIALOG_OK]="OK"
	[DIALOG_CANCEL]="CANCEL"
	[DIALOG_HELP]="HELP"
	[DIALOG_EXTRA]="EXTRA"
	[DIALOG_ITEM_HELP]="ITEM_HELP"
	[DIALOG_ERROR]="ERROR"
	[DIALOG_ESC]="ESC"
)

declare -gx BACKTITLE=''

declare -igx LINES COLUMNS

set_screen_size() {
	if [[ -z ${D["_defined_"]-} ]]; then
		run_script 'config_theme'
	fi
	COLUMNS=$(tput cols)
	LINES=$(tput lines)
}

_dialog_backtitle_() {
	local LeftHeading CenterHeading RightHeading

	local LeftHeading="{{|Hostname|}}${HOSTNAME}{{[-]}}"
	local -A FlagOption=(
		["DEBUG"]="DEBUG"
		["FORCE"]="FORCE"
		["VERBOSE"]="VERBOSE"
		["ASSUMEYES"]="YES"
	)
	local FlagsEnabled
	for Flag in DEBUG FORCE VERBOSE ASSUMEYES; do
		if [[ -n ${!Flag-} ]]; then
			if [[ -n ${FlagsEnabled-} ]]; then
				FlagsEnabled+="{{|ApplicationFlagsSpace|}}|{{[-]}}"
			fi
			FlagsEnabled+="{{|ApplicationFlags|}}${FlagOption["${Flag}"]}{{[-]}}"
		fi
	done
	if [[ -n ${FlagsEnabled-} ]]; then
		LeftHeading+=" {{|ApplicationFlagsBrackets|}}|${FlagsEnabled}{{|ApplicationFlagsBrackets|}}|{{[-]}}"
	fi
	local CenterHeading="{{|ApplicationName|}}${APPLICATION_NAME}{{[-]}}"

	local RightHeading=''

	local UpdateFlag="{{|ApplicationUpdate|}}*{{[-]}}"
	local ApplicationUpdateFlag=" "
	local ApplicationVersionColor="{{|ApplicationVersion|}}"
	local TemplatesUpdateFlag=" "
	local TemplatesVersionColor="{{|ApplicationVersion|}}"

	local CurrentVersion
	CurrentVersion="$(ds_version)"
	if [[ -z ${CurrentVersion} ]]; then
		CurrentVersion="$(ds_branch) Unknown Version"
	fi
	local CurrentTemplatesVersion
	CurrentTemplatesVersion="$(templates_version)"
	if [[ -z ${CurrentTemplatesVersion} ]]; then
		CurrentTemplatesVersion="$(templates_branch) Unknown Version"
	fi
	if ds_update_available; then
		ApplicationUpdateFlag=${UpdateFlag}
		ApplicationVersionColor="{{|ApplicationUpdate|}}"
	fi
	if templates_update_available; then
		TemplatesUpdateFlag=${UpdateFlag}
		TemplatesVersionColor="{{|ApplicationUpdate|}}"
	fi
	RightHeading+="${ApplicationUpdateFlag}{{|ApplicationVersionBrackets|}}A:[{{[-]}}${ApplicationVersionColor}${CurrentVersion}{{|ApplicationVersionBrackets|}}]{{[-]}}"
	RightHeading+="${TemplatesUpdateFlag}{{|ApplicationVersionBrackets|}}T:[{{[-]}}${TemplatesVersionColor}${CurrentTemplatesVersion}{{|ApplicationVersionBrackets|}}]{{[-]}}"

	local -i HeadingLength
	set_screen_size
	HeadingLength=$((COLUMNS - 2))

	local CleanLeftHeading CleanCenterHeading CleanRightHeading
	CleanLeftHeading="$(strip_styles "${LeftHeading}")"
	CleanCenterHeading="$(strip_styles "${CenterHeading}")"
	CleanRightHeading="$(strip_styles "${RightHeading}")"

	# Get the length of each heading
	local -i LeftHeadingLength=${#CleanLeftHeading}
	local -i CenterHeadingLength=${#CleanCenterHeading}
	local -i RightHeadingLength=${#CleanRightHeading}

	# Calculate padding
	local -i LeftPadding=$(((HeadingLength - CenterHeadingLength) / 2 - LeftHeadingLength))
	# Ensure left padding is not negative
	if [[ LeftPadding -lt 0 ]]; then
		LeftPadding=0
	fi
	local -i EndOfCenterHeading=$((LeftHeadingLength + LeftPadding + CenterHeadingLength))

	# Recalculate right padding based on adjusted left padding
	local RightPadding=$((HeadingLength - EndOfCenterHeading - RightHeadingLength))

	# Ensure right padding is not negative
	if [[ RightPadding -lt 0 ]]; then
		RightPadding=0
	fi

	BACKTITLE="$(
		printf "%s%*s%s%*s%s" \
			"${LeftHeading}" \
			"${LeftPadding}" " " \
			"${CenterHeading}" \
			"${RightPadding}" " " \
			"${RightHeading}"
	)"
	BACKTITLE=$(resolve_styles DC "${BACKTITLE}")
}

_dialog_() {
	local -a DialogOptions=()
	local Option
	for Option in "$@"; do
		DialogOptions+=("$(resolve_styles DC "${Option}")")
	done
	_dialog_backtitle_
	${DIALOG} --file "${DIALOG_OPTIONS_FILE}" --backtitle "${BACKTITLE}" "${DialogOptions[@]}"
}

# Check to see if we are already inside a dialog box
in_dialog_box() {
	# If we are in GUI mode, AND stdout is redirected, AND stderr is ALSO redirected
	# then we are almost certainly inside a '|& dialog_pipe' call.
	[[ ${PROMPT:-CLI} == GUI && ! -t 1 && ! -t 2 ]]
}

# Check to see if we should use a dialog box
use_dialog_box() {
	[[ ${PROMPT:-CLI} != GUI ]] && return 1

	# TRUE if Ready to start OR already inside one
	if in_dialog_box || [[ -t 1 && -t 2 ]]; then
		return 0
	fi
	return 1
}

# Pipe to Dialog Box Function
dialog_pipe() {
	local Title=${1:-}
	local SubTitle=${2:-}
	local TimeOut=${3:-0}
	set_screen_size
	local -i result=0
	strip_strings | _dialog_ \
		--title "{{|Title|}}${Title}" \
		--timeout "${TimeOut}" \
		--programbox "{{|Subtitle|}}${SubTitle}" \
		"$((LINES - D["WindowRowsAdjust"]))" "$((COLUMNS - D["WindowColsAdjust"]))" || result=$?
	echo -n "${S["BS"]}" >&2
	return ${result}
}
# Script Dialog Runner Function
run_script_dialog() {
	local Title=${1:-}
	local SubTitle=${2:-}
	local TimeOut=${3:-0}
	local SCRIPTSNAME=${4-}
	shift 4
	if use_dialog_box && ! in_dialog_box; then
		# Using the GUI, pipe output to a dialog box
		coproc {
			dialog_pipe "${Title}" "${SubTitle}" "${TimeOut}"
		}
		local -i DialogBox_PID=${COPROC_PID}
		local -i DialogBox_FD="${COPROC[1]}"
		local -i result=0
		run_script "${SCRIPTSNAME}" "$@" >&${DialogBox_FD} 2>&1 || result=$?
		exec {DialogBox_FD}<&- &> /dev/null || true
		wait ${DialogBox_PID} &> /dev/null || true
		return ${result}
	else
		run_script "${SCRIPTSNAME}" "$@"
		return
	fi
}

# Command Dialog Runner Function
run_command_dialog() {
	local Title=${1:-}
	local SubTitle=${2:-}
	local TimeOut=${3:-0}
	local CommandName=${4-}
	shift 4
	if [[ -n ${CommandName-} ]]; then
		if use_dialog_box; then
			# Using the GUI, pipe output to a dialog box
			"${CommandName}" "$@" |& dialog_pipe "${Title}" "${SubTitle}" "${TimeOut}"
			return "${PIPESTATUS[0]}"
		else
			"${CommandName}" "$@"
			return
		fi
	fi
}

# _parse_dialog_options_ DialogOptionsRef MaximizedRef CountRef "$@"
# Parses common --option[:value] flags from positional params into a DialogOptions array.
# Uses namerefs to modify the caller's DialogOptions and Maximized variables directly.
# Saves the count of consumed positional args to CountRef — caller must: shift "${CountRef}"
_parse_dialog_options_() {
	local -n _pdo_opts_="${1}"
	local -n _pdo_max_="${2}"
	local -n _pdo_cnt_="${3}"
	_pdo_max_=0
	_pdo_cnt_=0
	shift 3
	while [[ ${1-} == --* ]]; do
		case "${1}" in
			--maximized) _pdo_max_=1 ;;
			--timeout:*) _pdo_opts_+=("--timeout" "${1#*:}") ;;
			--extra-label:*) _pdo_opts_+=("--extra-button" "--extra-label" "${1#*:}") ;;
			--help-label:*) _pdo_opts_+=("--help-button" "--help-label" "${1#*:}") ;;
			--ok-label:* | --yes-label:* | --no-label:* | --cancel-label:* | --exit-label:*)
				_pdo_opts_+=("${1%:*}" "${1#*:}")
				;;
			--default-item:*) _pdo_opts_+=("--default-item" "${1#*:}") ;;
			--item-help) _pdo_opts_+=("${1}") ;;
			--*) _pdo_opts_+=("${1}") ;;
			*) break ;;
		esac
		shift
		((_pdo_cnt_++))
	done
}

# _dialog_calc_text_size_ WindowHeightRef WindowWidthRef Message Title Maximized
# Computes WindowHeight and WindowWidth for text-based dialogs (msgbox, inputbox, form, yesno).
# Uses namerefs to set the caller's WindowHeight and WindowWidth variables directly.
_dialog_calc_text_size_() {
	local -n _dcts_h_="${1}"
	local -n _dcts_w_="${2}"
	local _dcts_msg_="${3}"
	local _dcts_title_="${4}"
	local -i _dcts_max_="${5:-0}"
	set_screen_size
	local -i _dcts_hmax_=$((LINES - D["WindowRowsAdjust"]))
	local -i _dcts_wmax_=$((COLUMNS - D["WindowColsAdjust"]))
	if [[ ${_dcts_max_} -eq 1 ]]; then
		_dcts_h_=${_dcts_hmax_}
		_dcts_w_=${_dcts_wmax_}
	else
		_dcts_h_=0
		_dcts_w_=0
	fi
}

# _dialog_calc_list_size_ WindowHeightRef WindowWidthRef MenuHeightRef SubTitle Maximized
# Computes WindowHeight, WindowWidth, and MenuHeight for list-based dialogs (menu, checklist, radiolist, inputmenu).
# Uses namerefs to set the caller's WindowHeight, WindowWidth, and MenuHeight variables directly.
_dialog_calc_list_size_() {
	local -n _dcls_h_="${1}"
	local -n _dcls_w_="${2}"
	local -n _dcls_m_="${3}"
	local _dcls_sub_="${4}"
	local -i _dcls_max_="${5:-0}"
	set_screen_size
	local -i _dcls_hmax_=$((LINES - D["WindowRowsAdjust"]))
	local -i _dcls_wmax_=$((COLUMNS - D["WindowColsAdjust"]))
	_dcls_h_=0
	_dcls_w_=0
	_dcls_m_=0
	if [[ ${_dcls_max_} -eq 1 ]]; then
		_dcls_h_=${_dcls_hmax_}
		_dcls_w_=${_dcls_wmax_}
		local -i _dcls_tr_
		_dcls_tr_="$("${DIALOG}" --output-fd 1 --print-text-size "$(strip_styles "${_dcls_sub_}")" "${_dcls_h_}" "${_dcls_w_}" 2> /dev/null | cut -d ' ' -f 1)"
		_dcls_m_=$((LINES - D["TextRowsAdjust"] - _dcls_tr_))
	fi
}

dialog_info() {
	local Title="${1-}"
	shift || true
	local Message="${1-}"
	shift || true
	local -a DialogOptions=()
	local -i Maximized=0 _n_=0
	_parse_dialog_options_ DialogOptions Maximized _n_ "$@"
	shift "${_n_}"
	local -i result=0
	_dialog_ "${DialogOptions[@]}" --infobox "${Message}" 0 0 || result=$?
	echo -n "${S["BS"]}" >&2
	return ${result}
}

dialog_message() {
	local Title="${1-}"
	shift || true
	local Message="${1-}"
	shift || true
	dialog_msgbox "${Title}" "${Message}" "$@"
}

dialog_error() {
	dialog_message "{{|TitleError|}}${1-}" "${2-}" "--maximized"
}

dialog_warning() {
	dialog_message "{{|TitleWarning|}}${1-}" "${2-}" "--maximized"
}

dialog_success() {
	dialog_message "{{|TitleSuccess|}}${1-}" "${2-}" "--maximized"
}

dialog_yesno() {
	local Title="${1-}"
	shift || true
	local Message="${1-}"
	shift || true
	local -a DialogOptions=()
	local -i Maximized=0
	local BoxType="--yesno"

	local -i _n_=0
	_parse_dialog_options_ DialogOptions Maximized _n_ "$@"
	shift "${_n_}"

	DialogOptions+=(--output-fd 1)
	[[ -n ${Title} ]] && DialogOptions+=(--title "{{|TitleQuestion|}}${Title}")

	local -i WindowHeight=0 WindowWidth=0
	_dialog_calc_text_size_ WindowHeight WindowWidth "${Message}" "${Title}" "${Maximized}"

	local -i result=0
	_dialog_ "${DialogOptions[@]}" "${BoxType}" "${Message}" "${WindowHeight}" "${WindowWidth}" "$@" || result=$?
	echo -n "${S["BS"]}" >&2
	return ${result}
}

dialog_msgbox() {
	local Title="${1-}"
	shift || true
	local Message="${1-}"
	shift || true
	local -a DialogOptions=()
	local -i Maximized=0

	local -i _n_=0
	_parse_dialog_options_ DialogOptions Maximized _n_ "$@"
	shift "${_n_}"

	DialogOptions+=(--output-fd 1)
	[[ -n ${Title} ]] && DialogOptions+=(--title "{{|Title|}}${Title}")

	local -i WindowHeight=0 WindowWidth=0
	_dialog_calc_text_size_ WindowHeight WindowWidth "${Message}" "${Title}" "${Maximized}"

	local -i result=0
	_dialog_ "${DialogOptions[@]}" --msgbox "${Message}" "${WindowHeight}" "${WindowWidth}" "$@" || result=$?
	echo -n "${S["BS"]}" >&2
	return ${result}
}

dialog_inputbox() {
	local Title="${1-}"
	shift || true
	local Message="${1-}"
	shift || true
	local -a DialogOptions=()
	local -i Maximized=0

	local -i _n_=0
	_parse_dialog_options_ DialogOptions Maximized _n_ "$@"
	shift "${_n_}"

	DialogOptions+=(--output-fd 1)
	[[ -n ${Title} ]] && DialogOptions+=(--title "{{|Title|}}${Title}")

	local -i WindowHeight=0 WindowWidth=0
	_dialog_calc_text_size_ WindowHeight WindowWidth "${Message}" "${Title}" "${Maximized}"

	local -i result=0
	_dialog_ "${DialogOptions[@]}" --inputbox "${Message}" "${WindowHeight}" "${WindowWidth}" "$@" || result=$?
	echo -n "${S["BS"]}" >&2
	return ${result}
}

dialog_form() {
	local Title="${1-}"
	shift || true
	local Message="${1-}"
	shift || true
	local -a DialogOptions=()
	local -i Maximized=0

	local -i _n_=0
	_parse_dialog_options_ DialogOptions Maximized _n_ "$@"
	shift "${_n_}"

	DialogOptions+=(--output-fd 1)
	[[ -n ${Title} ]] && DialogOptions+=(--title "{{|Title|}}${Title}")

	local -i WindowHeight=0 WindowWidth=0
	_dialog_calc_text_size_ WindowHeight WindowWidth "${Message}" "${Title}" "${Maximized}"

	local -i result=0
	# form_height=0 (auto-size) is always appended before the field definitions in "$@"
	_dialog_ "${DialogOptions[@]}" --form "${Message}" "${WindowHeight}" "${WindowWidth}" 0 "$@" || result=$?
	echo -n "${S["BS"]}" >&2
	return ${result}
}

dialog_menu() {
	local Title="${1-}"
	shift || true
	local SubTitle="${1-}"
	shift || true
	local -a DialogOptions=()
	local -i Maximized=0

	local -i _n_=0
	_parse_dialog_options_ DialogOptions Maximized _n_ "$@"
	shift "${_n_}"
	local -a Items=("$@")

	DialogOptions+=(--output-fd 1)
	[[ -n ${Title} ]] && DialogOptions+=(--title "{{|Title|}}${Title}")

	local -i WindowHeight=0 WindowWidth=0 MenuHeight=0
	_dialog_calc_list_size_ WindowHeight WindowWidth MenuHeight "${SubTitle}" "${Maximized}"

	local StyledSubTitle=""
	[[ -n ${SubTitle} ]] && StyledSubTitle="{{|Subtitle|}}${SubTitle}"

	local -i result=0
	_dialog_ "${DialogOptions[@]}" --menu "${StyledSubTitle}" "${WindowHeight}" "${WindowWidth}" "${MenuHeight}" "${Items[@]}" || result=$?
	echo -n "${S["BS"]}" >&2
	return ${result}
}

dialog_checklist() {
	local Title="${1-}"
	shift || true
	local SubTitle="${1-}"
	shift || true
	local -a DialogOptions=()
	local -i Maximized=0

	local -i _n_=0
	_parse_dialog_options_ DialogOptions Maximized _n_ "$@"
	shift "${_n_}"
	local -a Items=("$@")

	DialogOptions+=(--output-fd 1)
	[[ -n ${Title} ]] && DialogOptions+=(--title "{{|Title|}}${Title}")

	local -i WindowHeight=0 WindowWidth=0 MenuHeight=0
	_dialog_calc_list_size_ WindowHeight WindowWidth MenuHeight "${SubTitle}" "${Maximized}"

	local StyledSubTitle=""
	[[ -n ${SubTitle} ]] && StyledSubTitle="{{|Subtitle|}}${SubTitle}"

	local -i result=0
	_dialog_ "${DialogOptions[@]}" --checklist "${StyledSubTitle}" "${WindowHeight}" "${WindowWidth}" "${MenuHeight}" "${Items[@]}" || result=$?
	echo -n "${S["BS"]}" >&2
	return ${result}
}

dialog_radiolist() {
	local Title="${1-}"
	shift || true
	local SubTitle="${1-}"
	shift || true
	local -a DialogOptions=()
	local -i Maximized=0

	local -i _n_=0
	_parse_dialog_options_ DialogOptions Maximized _n_ "$@"
	shift "${_n_}"
	local -a Items=("$@")

	DialogOptions+=(--output-fd 1)
	[[ -n ${Title} ]] && DialogOptions+=(--title "{{|Title|}}${Title}")

	local -i WindowHeight=0 WindowWidth=0 MenuHeight=0
	_dialog_calc_list_size_ WindowHeight WindowWidth MenuHeight "${SubTitle}" "${Maximized}"

	local StyledSubTitle=""
	[[ -n ${SubTitle} ]] && StyledSubTitle="{{|Subtitle|}}${SubTitle}"

	local -i result=0
	_dialog_ "${DialogOptions[@]}" --radiolist "${StyledSubTitle}" "${WindowHeight}" "${WindowWidth}" "${MenuHeight}" "${Items[@]}" || result=$?
	echo -n "${S["BS"]}" >&2
	return ${result}
}

dialog_inputmenu() {
	local Title="${1-}"
	shift || true
	local SubTitle="${1-}"
	shift || true
	local -a DialogOptions=()
	local -i Maximized=0

	local -i _n_=0
	_parse_dialog_options_ DialogOptions Maximized _n_ "$@"
	shift "${_n_}"
	local -a Items=("$@")

	DialogOptions+=(--output-fd 1)
	[[ -n ${Title} ]] && DialogOptions+=(--title "{{|Title|}}${Title}")

	local -i WindowHeight=0 WindowWidth=0 MenuHeight=0
	_dialog_calc_list_size_ WindowHeight WindowWidth MenuHeight "${SubTitle}" "${Maximized}"

	local StyledSubTitle=""
	[[ -n ${SubTitle} ]] && StyledSubTitle="{{|Subtitle|}}${SubTitle}"

	local -i result=0
	_dialog_ "${DialogOptions[@]}" --inputmenu "${StyledSubTitle}" "${WindowHeight}" "${WindowWidth}" "${MenuHeight}" "${Items[@]}" || result=$?
	echo -n "${S["BS"]}" >&2
	return ${result}
}

invalid_dialog_button() {
	local -i DialogButtonNumber=${1}
	local -l NoticeType=${2:-fatal}
	local DialogButton="${DIALOG_BUTTONS[DialogButtonNumber]-#${DialogButtonNumber}}"
	${NoticeType} "Unexpected dialog button '{{|ButtonName|}}${DialogButton}{{[-]}}' pressed."
}
