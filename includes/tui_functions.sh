#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -gx DIALOG
DIALOG=$(command -v dialog) || true
declare -gx WHIPTAIL
WHIPTAIL=$(command -v whiptail) || true

declare -Agx DC
declare -Agx D

declare -rgx DIALOGRC_NAME='.dialogrc'
declare -rgx DIALOG_OPTIONS_NAME='.dialogoptions'

declare -rgx DIALOGRC="${TEMP_FOLDER}/${DIALOGRC_NAME}"
declare -rgx DIALOG_OPTIONS_FILE="${TEMP_FOLDER}/${DIALOG_OPTIONS_NAME}"

declare -rigx DIALOG_CANCEL=1
declare -rigx DIALOGTIMEOUT=3
declare -rigx DIALOG_OK=0
declare -rigx DIALOG_HELP=2
declare -rigx DIALOG_EXTRA=3
declare -rigx DIALOG_ITEM_HELP=4
declare -rigx DIALOG_EXIT=5
declare -rigx DIALOG_ERROR=254
declare -rigx DIALOG_ESC=255
declare -ragx DIALOG_BUTTONS=(
	[DIALOG_OK]="OK"
	[DIALOG_CANCEL]="CANCEL"
	[DIALOG_HELP]="HELP"
	[DIALOG_EXTRA]="EXTRA"
	[DIALOG_ITEM_HELP]="ITEM_HELP"
	[DIALOG_EXIT]="EXIT"
	[DIALOG_ERROR]="ERROR"
	[DIALOG_ESC]="ESC"
)

declare -agx WHIPTAIL_OPTIONS=''

declare -gx BACKTITLE=''

declare -igx LINES COLUMNS

use_dialog() {
	[[ ${D["ui.display_engine"]-} == dialog && -n ${DIALOG-} ]]
}

use_whiptail() {
	[[ ${D["ui.display_engine"]-} == whiptail && -n ${WHIPTAIL-} ]]
}

set_screen_size() {
	if [[ -z ${D["_defined_"]-} ]]; then
		run_script 'config_theme'
	fi
	COLUMNS=$(tput cols)
	LINES=$(tput lines)
}

_tui_backtitle_() {
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
	ds_version_into CurrentVersion
	if [[ -z ${CurrentVersion} ]]; then
		local _ds_br_
		ds_branch_into _ds_br_
		CurrentVersion="${_ds_br_} Unknown Version"
	fi
	local CurrentTemplatesVersion
	templates_version_into CurrentTemplatesVersion
	if [[ -z ${CurrentTemplatesVersion} ]]; then
		local _temp_br_
		templates_branch_into _temp_br_
		CurrentTemplatesVersion="${_temp_br_} Unknown Version"
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
	strip_styles_into CleanLeftHeading "${LeftHeading}"
	strip_styles_into CleanCenterHeading "${CenterHeading}"
	strip_styles_into CleanRightHeading "${RightHeading}"

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

	printf -v BACKTITLE "%s%*s%s%*s%s" \
		"${LeftHeading}" \
		"${LeftPadding}" " " "${CenterHeading}" "${RightPadding}" " " \
		"${RightHeading}"

	if use_dialog; then
		# Using dialog, resolve styles to dialog codes
		resolve_styles_into BACKTITLE DC "${BACKTITLE}"
	else
		# Using whiptail, strip styles
		strip_styles_into BACKTITLE "${BACKTITLE}"
	fi
}

_dialog_() {
	local -a DialogOptions=()
	local Option _rsi_opt_
	for Option in "$@"; do
		resolve_styles_into _rsi_opt_ DC "${Option}"
		DialogOptions+=("${_rsi_opt_}")
	done

	_tui_backtitle_
	${DIALOG} --file "${DIALOG_OPTIONS_FILE}" --backtitle "${BACKTITLE}" "${DialogOptions[@]}"
}
_whiptail_() {
	local -a WhiptailOptions=()
	local Option _ssi_opt_
	for Option in "$@"; do
		strip_styles_into _ssi_opt_ "${Option}"
		WhiptailOptions+=("${_ssi_opt_}")
	done

	_tui_backtitle_
	${WHIPTAIL} "${WHIPTAIL_OPTIONS[@]}" --backtitle "${BACKTITLE}" "${WhiptailOptions[@]}" 3>&1 1>&2 2>&3
}

tui_box_enter() {
	declare -gx TUI_IN_BOX=$((${TUI_IN_BOX:-0} + 1))
}
tui_box_exit() {
	declare -gx TUI_IN_BOX=$((${TUI_IN_BOX:-0} - 1))
	if [[ ${TUI_IN_BOX:-0} -le 0 ]]; then
		unset TUI_IN_BOX
	fi
}
# Check to see if we are already inside a dialog box
in_tui_box() {
	[[ ${TUI_IN_BOX:-0} -gt 0 || ${TUI_IN_BOX-} == true ]]
}

# Check to see if we should use a dialog box
use_tui_box() {
	[[ ${PROMPT:-CLI} != GUI ]] && return 1

	# TRUE if Ready to start OR already inside one
	if in_tui_box || [[ -t 1 && -t 2 ]]; then
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
whiptail_pipe() {
	if [[ -t 1 ]]; then
		cat
	else
		cat > /dev/tty
	fi
}
tui_pipe() {
	if use_dialog; then
		dialog_pipe "$@"
	else
		whiptail_pipe "$@"
	fi
}

tui_pipe_open() {
	local -n _tpo_fd_="${1}"
	local -n _tpo_pid_="${2}"
	local Title="${3:-}" SubTitle="${4:-}" TimeOut="${5:-0}"
	if use_dialog && use_tui_box; then
		coproc {
			dialog_pipe "${Title}" "${SubTitle}" "${TimeOut}"
		}
		_tpo_fd_=${COPROC[1]}
		_tpo_pid_=${COPROC_PID}
		tui_box_enter
	else
		_tpo_fd_=1
		_tpo_pid_=0
	fi
}
tui_pipe_close() {
	local -n _tpc_fd_="${1}"
	local -n _tpc_pid_="${2}"
	if [[ _tpc_fd_ -ne 1 ]]; then
		local _tpc_fd_val_=${_tpc_fd_}
		exec {_tpc_fd_val_}<&- &> /dev/null || true
		wait "${_tpc_pid_}" &> /dev/null || true
		tui_box_exit
	fi
}

dialog_run_script() {
	local Title=${1:-}
	local SubTitle=${2:-}
	local TimeOut=${3:-0}
	local SCRIPTSNAME=${4-}
	shift 4
	if ! in_tui_box; then
		coproc {
			dialog_pipe "${Title}" "${SubTitle}" "${TimeOut}"
		}
		local -i DialogBox_PID=${COPROC_PID}
		local -i DialogBox_FD="${COPROC[1]}"
		local -i result=0
		tui_box_enter
		run_script "${SCRIPTSNAME}" "$@" >&${DialogBox_FD} 2>&1 || result=$?
		tui_box_exit
		exec {DialogBox_FD}<&- &> /dev/null || true
		wait ${DialogBox_PID} &> /dev/null || true
		return ${result}
	else
		run_script "${SCRIPTSNAME}" "$@"
	fi
}
whiptail_run_script() {
	local Title=${1:-}
	local SubTitle=${2:-}
	local TimeOut=${3:-0}
	local SCRIPTSNAME=${4-}
	shift 4
	run_script "${SCRIPTSNAME}" "$@"
}
run_script_tui() {
	if use_dialog && use_tui_box; then
		dialog_run_script "$@"
	else
		whiptail_run_script "$@"
	fi
}

dialog_run_command() {
	local Title=${1:-}
	local SubTitle=${2:-}
	local TimeOut=${3:-0}
	local CommandName=${4-}
	shift 4
	if [[ -n ${CommandName-} ]]; then
		TUI_IN_BOX=1 "${CommandName}" "$@" |& dialog_pipe "${Title}" "${SubTitle}" "${TimeOut}"
		return "${PIPESTATUS[0]}"
	fi
}
whiptail_run_command() {
	local Title=${1:-}
	local SubTitle=${2:-}
	local TimeOut=${3:-0}
	local CommandName=${4-}
	shift 4
	if [[ -n ${CommandName-} ]]; then
		"${CommandName}" "$@"
	fi
}
run_command_tui() {
	if use_dialog && use_tui_box; then
		dialog_run_command "$@"
	else
		whiptail_run_command "$@"
	fi
}

# _dialog_parse_options_ DialogOptionsRef MaximizedRef CountRef "$@"
# Parses common --option[:value] flags from positional params into a DialogOptions array.
# Uses namerefs to modify the caller's DialogOptions and Maximized variables directly.
# Saves the count of consumed positional args to CountRef — caller must: shift "${CountRef}"
# Sets _DIALOG_EXIT_BUTTON_ to 1 if --exit-button was present (caller must remap return codes).
_dialog_parse_options_() {
	local -n _dpo_opts_="${1}"
	local -n _dpo_max_="${2}"
	local -n _dpo_cnt_="${3}"
	_dpo_max_=0
	_dpo_cnt_=0
	_DIALOG_EXIT_BUTTON_=0
	local _dpo_exit_btn_=0
	local _dpo_cancel_label_=""
	shift 3
	while [[ ${1-} == --* ]]; do
		case "${1}" in
			--maximized) _dpo_max_=1 ;;
			--timeout:*) _dpo_opts_+=("--timeout" "${1#*:}") ;;
			--exit-button) _dpo_exit_btn_=1 ;;
			--extra-label:*) _dpo_opts_+=("--extra-button" "--extra-label" "${1#*:}") ;;
			--help-label:*) _dpo_opts_+=("--help-button" "--help-label" "${1#*:}") ;;
			--cancel-label:*) _dpo_cancel_label_="${1#*:}" ;;
			--ok-label:* | --yes-label:* | --no-label:* | --exit-label:*)
				_dpo_opts_+=("${1%:*}" "${1#*:}")
				;;
			--default-item:*) _dpo_opts_+=("--default-item" "${1#*:}") ;;
			--item-help) _dpo_opts_+=("${1}") ;;
			--*) _dpo_opts_+=("${1}") ;;
			*) break ;;
		esac
		shift
		((_dpo_cnt_++))
	done
	if [[ _dpo_exit_btn_ -eq 1 ]]; then
		_DIALOG_EXIT_BUTTON_=1
		_dpo_opts_+=("--extra-button" "--extra-label" "${_dpo_cancel_label_:-Cancel}" "--cancel-label" "Exit")
	elif [[ -n ${_dpo_cancel_label_} ]]; then
		_dpo_opts_+=("--cancel-label" "${_dpo_cancel_label_}")
	fi
}

# _whiptail_parse_options_ WhiptailOptionsRef MaximizedRef CountRef "$@"
# Parses common --option[:value] flags from positional params into a WhiptailOptions array.
# Uses namerefs to modify the caller's WhiptailOptions and Maximized variables directly.
# Saves the count of consumed positional args to CountRef — caller must: shift "${CountRef}"
_whiptail_parse_options_() {
	local -n _wpo_opts_="${1}"
	local -n _wpo_max_="${2}"
	local -n _wpo_cnt_="${3}"
	_wpo_max_=0
	_wpo_cnt_=0
	shift 3
	while [[ ${1-} == --* ]]; do
		case "${1}" in
			--maximized) _wpo_max_=1 ;;
			--timeout:*) ;;     # ignore
			--exit-button) ;;   # ignore — whiptail shows default OK + Cancel
			--extra-button) ;;  # ignore — no third button in whiptail
			--extra-label:*) ;; # ignore
			--help-label:*) ;;  # ignore
			--no-collapse) ;;   # ignore — dialog-only
			--no-hot-list) ;;   # ignore — dialog-only
			--ok-label:*) _wpo_opts_+=("--ok-button" "${1#*:}") ;;
			--yes-label:*) _wpo_opts_+=("--yes-button" "${1#*:}") ;;
			--no-label:*) _wpo_opts_+=("--no-button" "${1#*:}") ;;
			--cancel-label:*) _wpo_opts_+=("--cancel-button" "${1#*:}") ;;
			--exit-label:*) ;; # ignore
			--default-item:*) _wpo_opts_+=("--default-item" "${1#*:}") ;;
			--item-help) _wpo_opts_+=("${1}") ;;
			--*) _wpo_opts_+=("${1}") ;;
			*) break ;;
		esac
		shift
		((_wpo_cnt_++))
	done
}

# _dialog_calc_list_width_ WindowWidthRef Title SubTitle FieldsPerItem Items...
# Computes WindowWidth for non-maximized list dialogs based on content.
# Sets width to wmax if content overflows, 0 (auto) otherwise.
_dialog_calc_list_width_() {
	local -n _dclw_w_="${1}"
	local _dclw_title_="${2}"
	local _dclw_sub_="${3}"
	local -i _dclw_fpi_="${4}"
	shift 4
	set_screen_size
	local -i _dclw_wmax_=$((COLUMNS - D["WindowColsAdjust"]))
	local -i _dclw_tagw_=0 _dclw_itemw_=0
	local -i _dclw_i_
	for ((_dclw_i_ = 0; _dclw_i_ < $#; _dclw_i_ += _dclw_fpi_)); do
		local _dclw_tag_ _dclw_item_
		strip_styles_into _dclw_tag_ "${@:$((_dclw_i_ + 1)):1}"  # field 1: tag
		strip_styles_into _dclw_item_ "${@:$((_dclw_i_ + 2)):1}" # field 2: description (never item-help)
		[[ ${#_dclw_tag_} -gt _dclw_tagw_ ]] && _dclw_tagw_=${#_dclw_tag_}
		[[ ${#_dclw_item_} -gt _dclw_itemw_ ]] && _dclw_itemw_=${#_dclw_item_}
		[[ $((3 + _dclw_tagw_ + 2 + _dclw_itemw_ + 3)) -ge _dclw_wmax_ ]] && _dclw_w_=${_dclw_wmax_} && return
	done
	local -i _dclw_labelw_=$((3 + _dclw_tagw_ + 2 + _dclw_itemw_ + 3))
	local _dclw_clean_sub_
	strip_styles_into _dclw_clean_sub_ "${_dclw_sub_}"
	local -i _dclw_subw_
	_dclw_subw_="$("${DIALOG}" --output-fd 1 --print-text-size "${_dclw_clean_sub_}" 0 0 2> /dev/null | cut -d ' ' -f 2)"
	local -i _dclw_titlew_=$((3 + 12 + ${#_dclw_title_} + 3))
	local -i _dclw_req_=$((_dclw_labelw_ > _dclw_subw_ ? _dclw_labelw_ : _dclw_subw_))
	_dclw_req_=$((_dclw_req_ > _dclw_titlew_ ? _dclw_req_ : _dclw_titlew_))
	[[ ${_dclw_req_} -ge ${_dclw_wmax_} ]] && _dclw_w_=${_dclw_wmax_} || _dclw_w_=0
}

# _whiptail_calc_list_width_ WindowWidthRef Title SubTitle FieldsPerItem Items...
# Computes WindowWidth for non-maximized list dialogs based on content.
# Sets width to wmax if content overflows, 0 (auto) otherwise.
_whiptail_calc_list_width_() {
	local -n _dclw_w_="${1}"
	local _dclw_title_="${2}"
	local _dclw_sub_="${3}"
	local -i _dclw_fpi_="${4}"
	shift 4
	_dclw_w_=0
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

# _whiptail_calc_text_size_ WindowHeightRef WindowWidthRef Message Title Maximized
# Computes WindowHeight and WindowWidth for text-based dialogs (msgbox, inputbox, form, yesno).
# Uses namerefs to set the caller's WindowHeight and WindowWidth variables directly.
_whiptail_calc_text_size_() {
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

# _dialog_calc_list_size_ WindowHeightRef WindowWidthRef MenuHeightRef SubTitle Maximized ItemCount
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
	local _dcls_clean_sub_
	strip_styles_into _dcls_clean_sub_ "${_dcls_sub_}"
	if [[ ${_dcls_max_} -eq 1 ]]; then
		_dcls_h_=${_dcls_hmax_}
		_dcls_w_=${_dcls_wmax_}
		local -i _dcls_tr_
		_dcls_tr_="$("${DIALOG}" --output-fd 1 --print-text-size "${_dcls_clean_sub_}" "${_dcls_h_}" "${_dcls_w_}" 2> /dev/null | cut -d ' ' -f 1)"
		_dcls_m_=$((LINES - D["TextRowsAdjust"] - _dcls_tr_))
	else
		local -i _dcls_sh_
		_dcls_sh_="$("${DIALOG}" --output-fd 1 --print-text-size "${_dcls_clean_sub_}" 0 0 2> /dev/null | cut -d ' ' -f 1)"
		local -i _dcls_ic_="${6:-0}"
		local -i _dcls_required_=$((_dcls_sh_ + _dcls_ic_ + 8))
		if [[ ${_dcls_required_} -ge ${_dcls_hmax_} ]]; then
			_dcls_h_=${_dcls_hmax_}
			local -i _dcls_tr_
			_dcls_tr_="$("${DIALOG}" --output-fd 1 --print-text-size "${_dcls_clean_sub_}" "${_dcls_h_}" "${_dcls_w_}" 2> /dev/null | cut -d ' ' -f 1)"
			_dcls_m_=$((LINES - D["TextRowsAdjust"] - _dcls_tr_))
		else
			_dcls_m_=${_dcls_ic_}
		fi
	fi
}

# _whiptail_calc_list_size_ WindowHeightRef WindowWidthRef MenuHeightRef SubTitle Maximized ItemCount
# Computes WindowHeight, WindowWidth, and MenuHeight for list-based dialogs (menu, checklist, radiolist, inputmenu).
# Uses namerefs to set the caller's WindowHeight, WindowWidth, and MenuHeight variables directly.
_whiptail_calc_list_size_() {
	local -n _dcls_h_="${1}"
	local -n _dcls_w_="${2}"
	local -n _dcls_m_="${3}"
	#local _dcls_sub_="${4}"
	#local -i _dcls_max_="${5:-0}"
	_dcls_h_=0
	_dcls_w_=0
	_dcls_m_=0
}

# _strip_helptext_in_place_ <ArrayName> [<Interval>]
# Removes every Nth element from an array, starting from the Nth element.
_strip_helptext_in_place_() {
	local -n _shtip_ref_arr=${1}
	local -i Interval=${2:-3}

	[[ ${#_shtip_ref_arr[@]} -eq 0 ]] && return 0

	local -i ArraySize=${#_shtip_ref_arr[@]}
	for ((i = Interval - 1; i < ArraySize; i += Interval)); do
		unset "_shtip_ref_arr[$i]"
	done
	_shtip_ref_arr=("${_shtip_ref_arr[@]}")
}

dialog_info() {
	local Title="${1-}"
	shift || true
	local Message="${1-}"
	shift || true
	local -a DialogOptions=()
	local -i Maximized=0 _n_=0
	local BoxType="--infobox"

	_dialog_parse_options_ DialogOptions Maximized _n_ "$@"
	shift "${_n_}"
	local -i result=0
	_dialog_ "${DialogOptions[@]}" "${BoxType}" "${Message}" 0 0 || result=$?
	echo -n "${S["BS"]}" >&2
	return ${result}
}
whiptail_info() {
	local Title="${1-}"
	shift || true
	local Message="${1-}"
	shift || true
	local -a WhiptailOptions=()
	local -i Maximized=0 _n_=0
	local BoxType="--infobox"

	_whiptail_parse_options_ WhiptailOptions Maximized _n_ "$@"
	shift "${_n_}"
	[[ -n ${Title} ]] && WhiptailOptions+=(--title "${Title}")
	local -i result=0
	_whiptail_ "${WhiptailOptions[@]}" "${BoxType}" "${Message}" 0 0 || result=$?
	echo -n "${S["BS"]}" >&2
	return ${result}
}
tui_info() {
	if use_dialog; then
		dialog_info "$@"
	else
		whiptail_info "$@"
	fi
}

tui_message() {
	local Title="${1-}"
	shift || true
	local Message="${1-}"
	shift || true
	tui_msgbox "${Title}" "${Message}" "$@"
}

tui_error() {
	tui_msgbox "{{|TitleError|}}${1-}" "${2-}" "--maximized"
}

tui_warning() {
	tui_message "{{|TitleWarning|}}${1-}" "${2-}" "--maximized"
}

tui_success() {
	tui_message "{{|TitleSuccess|}}${1-}" "${2-}" "--maximized"
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
	_dialog_parse_options_ DialogOptions Maximized _n_ "$@"
	shift "${_n_}"

	[[ -n ${Title} ]] && DialogOptions+=(--title "{{|TitleQuestion|}}${Title}")

	local -i WindowHeight=0 WindowWidth=0
	_dialog_calc_text_size_ WindowHeight WindowWidth "${Message}" "${Title}" "${Maximized}"

	local -i result=0
	_dialog_ "${DialogOptions[@]}" "${BoxType}" "${Message}" "${WindowHeight}" "${WindowWidth}" "$@" || result=$?
	echo -n "${S["BS"]}" >&2
	return ${result}
}
whiptail_yesno() {
	local Title="${1-}"
	shift || true
	local Message="${1-}"
	shift || true
	local -a WhiptailOptions=()
	local -i Maximized=0
	local BoxType="--yesno"

	local -i _n_=0
	_whiptail_parse_options_ WhiptailOptions Maximized _n_ "$@"
	shift "${_n_}"

	[[ -n ${Title} ]] && WhiptailOptions+=(--title "${Title}")

	local -i WindowHeight=0 WindowWidth=0
	_whiptail_calc_text_size_ WindowHeight WindowWidth "${Message}" "${Title}" "${Maximized}"

	local -i result=0
	_whiptail_ "${WhiptailOptions[@]}" "${BoxType}" "${Message}" "${WindowHeight}" "${WindowWidth}" "$@" || result=$?
	echo -n "${S["BS"]}" >&2
	return ${result}
}
tui_yesno() {
	if use_dialog; then
		dialog_yesno "$@"
	else
		whiptail_yesno "$@"
	fi
}

dialog_msgbox() {
	local Title="${1-}"
	shift || true
	local Message="${1-}"
	shift || true
	local -a DialogOptions=()
	local -i Maximized=0
	local BoxType="--msgbox"

	local -i _n_=0
	_dialog_parse_options_ DialogOptions Maximized _n_ "$@"
	shift "${_n_}"

	[[ -n ${Title} ]] && DialogOptions+=(--title "{{|Title|}}${Title}")

	local -i WindowHeight=0 WindowWidth=0
	_dialog_calc_text_size_ WindowHeight WindowWidth "${Message}" "${Title}" "${Maximized}"

	local -i result=0
	_dialog_ "${DialogOptions[@]}" "${BoxType}" "${Message}" "${WindowHeight}" "${WindowWidth}" "$@" || result=$?
	echo -n "${S["BS"]}" >&2
	return ${result}
}
whiptail_msgbox() {
	local Title="${1-}"
	shift || true
	local Message="${1-}"
	shift || true
	local -a WhiptailOptions=()
	local -i Maximized=0
	local BoxType="--msgbox"

	local -i _n_=0
	_whiptail_parse_options_ WhiptailOptions Maximized _n_ "$@"
	shift "${_n_}"

	[[ -n ${Title} ]] && WhiptailOptions+=(--title "${Title}")

	local -i WindowHeight=0 WindowWidth=0
	_whiptail_calc_text_size_ WindowHeight WindowWidth "${Message}" "${Title}" "${Maximized}"

	local -i result=0
	_whiptail_ "${WhiptailOptions[@]}" "${BoxType}" "${Message}" "${WindowHeight}" "${WindowWidth}" "$@" || result=$?
	echo -n "${S["BS"]}" >&2
	return ${result}
}
tui_msgbox() {
	if use_dialog; then
		dialog_msgbox "$@"
	else
		whiptail_msgbox "$@"
	fi
}

dialog_inputbox() {
	local Title="${1-}"
	shift || true
	local Message="${1-}"
	shift || true
	local -a DialogOptions=()
	local -i Maximized=0

	local -i _n_=0
	_dialog_parse_options_ DialogOptions Maximized _n_ "$@"
	shift "${_n_}"

	[[ -n ${Title} ]] && DialogOptions+=(--title "{{|Title|}}${Title}")

	local -i WindowHeight=0 WindowWidth=0
	_dialog_calc_text_size_ WindowHeight WindowWidth "${Message}" "${Title}" "${Maximized}"

	local -i result=0
	_dialog_ "${DialogOptions[@]}" --inputbox "${Message}" "${WindowHeight}" "${WindowWidth}" "$@" || result=$?
	echo -n "${S["BS"]}" >&2
	return ${result}
}
whiptail_inputbox() {
	local Title="${1-}"
	shift || true
	local Message="${1-}"
	shift || true
	local -a DialogOptions=()
	local -i Maximized=0

	local -i _n_=0
	_whiptail_parse_options_ WhiptailOptions Maximized _n_ "$@"
	shift "${_n_}"

	[[ -n ${Title} ]] && WhiptailOptions+=(--title "${Title}")

	local -i WindowHeight=0 WindowWidth=0
	_whiptail_calc_text_size_ WindowHeight WindowWidth "${Message}" "${Title}" "${Maximized}"

	local -i result=0
	_whiptail_ "${WhiptailOptions[@]}" --inputbox "${Message}" "${WindowHeight}" "${WindowWidth}" "$@" || result=$?
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
	local -i _DIALOG_EXIT_BUTTON_=0
	_dialog_parse_options_ DialogOptions Maximized _n_ "$@"
	shift "${_n_}"

	[[ -n ${Title} ]] && DialogOptions+=(--title "{{|Title|}}${Title}")

	local -i WindowHeight=0 WindowWidth=0
	_dialog_calc_text_size_ WindowHeight WindowWidth "${Message}" "${Title}" "${Maximized}"

	local -i result=0
	# form_height=0 (auto-size) is always appended before the field definitions in "$@"
	_dialog_ "${DialogOptions[@]}" --form "${Message}" "${WindowHeight}" "${WindowWidth}" 0 "$@" || result=$?
	echo -n "${S["BS"]}" >&2
	[[ _DIALOG_EXIT_BUTTON_ -eq 1 && result -eq DIALOG_CANCEL ]] && return ${DIALOG_EXIT}
	[[ _DIALOG_EXIT_BUTTON_ -eq 1 && result -eq DIALOG_EXTRA ]] && return ${DIALOG_CANCEL}
	return ${result}
}
whiptail_form() {
	local Title="${1-}"
	shift || true
	local Message="${1-}"
	shift || true
	local -a WhiptailOptions=()
	local -i Maximized=0

	local -i _n_=0
	_whiptail_parse_options_ WhiptailOptions Maximized _n_ "$@"
	shift "${_n_}"

	[[ -n ${Title} ]] && WhiptailOptions+=(--title "${Title}")

	local -i WindowHeight=0 WindowWidth=0
	_whiptail_calc_text_size_ WindowHeight WindowWidth "${Message}" "${Title}" "${Maximized}"

	local -i result=0
	# form_height=0 (auto-size) is always appended before the field definitions in "$@"
	_whiptail_ "${WhiptailOptions[@]}" --form "${Message}" "${WindowHeight}" "${WindowWidth}" 0 "$@" || result=$?
	echo -n "${S["BS"]}" >&2
	return ${result}
}
tui_form() {
	if use_dialog; then
		dialog_form "$@"
	else
		whiptail_form "$@"
	fi
}

dialog_menu() {
	local Title="${1-}"
	shift || true
	local SubTitle="${1-}"
	shift || true
	local -a DialogOptions=()
	local -i Maximized=0

	local -i _n_=0
	local -i _DIALOG_EXIT_BUTTON_=0
	_dialog_parse_options_ DialogOptions Maximized _n_ "$@"
	shift "${_n_}"
	local -a Items=("$@")

	[[ -n ${Title} ]] && DialogOptions+=(--title "{{|Title|}}${Title}")

	local -i FieldsPerItem=2
	local _opt_
	for _opt_ in "${DialogOptions[@]}"; do
		[[ ${_opt_} == "--item-help" ]] && FieldsPerItem=3 && break
	done
	local -i ItemCount=$((${#Items[@]} / FieldsPerItem))
	local -i WindowHeight=0 WindowWidth=0 MenuHeight=0
	_dialog_calc_list_size_ WindowHeight WindowWidth MenuHeight "${SubTitle}" "${Maximized}" "${ItemCount}"
	[[ ${Maximized} -eq 0 ]] && _dialog_calc_list_width_ WindowWidth "${Title}" "${SubTitle}" "${FieldsPerItem}" "${Items[@]}"

	local StyledSubTitle=""
	[[ -n ${SubTitle} ]] && StyledSubTitle="{{|Subtitle|}}${SubTitle}"

	local -i result=0
	_dialog_ "${DialogOptions[@]}" --menu "${StyledSubTitle}" "${WindowHeight}" "${WindowWidth}" "${MenuHeight}" "${Items[@]}" || result=$?
	echo -n "${S["BS"]}" >&2
	[[ _DIALOG_EXIT_BUTTON_ -eq 1 && result -eq DIALOG_CANCEL ]] && return ${DIALOG_EXIT}
	[[ _DIALOG_EXIT_BUTTON_ -eq 1 && result -eq DIALOG_EXTRA ]] && return ${DIALOG_CANCEL}
	return ${result}
}

whiptail_menu() {
	local Title="${1-}"
	shift || true
	local SubTitle="${1-}"
	shift || true
	local -a WhiptailOptions=()
	local -i Maximized=0

	local -i _n_=0
	_whiptail_parse_options_ WhiptailOptions Maximized _n_ "$@"
	shift "${_n_}"
	local -a Items=("$@")

	[[ -n ${Title} ]] && WhiptailOptions+=(--title "${Title}")

	local -i FieldsPerItem=2
	local Option
	local -a FilteredOptions=()
	for Option in "${WhiptailOptions[@]}"; do
		if [[ ${Option} == "--item-help" ]]; then
			FieldsPerItem=3
		else
			FilteredOptions+=("${Option}")
		fi
	done
	WhiptailOptions=("${FilteredOptions[@]}")
	local -i ItemCount=$((${#Items[@]} / FieldsPerItem))
	if [[ FieldsPerItem -eq 3 ]]; then
		_strip_helptext_in_place_ Items 3
		FieldsPerItem=2
	fi
	local -i WindowHeight=0 WindowWidth=0 MenuHeight=0
	_whiptail_calc_list_size_ WindowHeight WindowWidth MenuHeight "${SubTitle}" "${Maximized}" "${ItemCount}"
	[[ ${Maximized} -eq 0 ]] && _whiptail_calc_list_width_ WindowWidth "${Title}" "${SubTitle}" "${FieldsPerItem}" "${Items[@]}"

	local -i result=0
	_whiptail_ "${WhiptailOptions[@]}" --menu "${SubTitle}" "${WindowHeight}" "${WindowWidth}" "${MenuHeight}" "${Items[@]}" || result=$?
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
	local -i _DIALOG_EXIT_BUTTON_=0
	_dialog_parse_options_ DialogOptions Maximized _n_ "$@"
	shift "${_n_}"
	local -a Items=("$@")

	[[ -n ${Title} ]] && DialogOptions+=(--title "{{|Title|}}${Title}")

	local -i FieldsPerItem=3
	local _opt_
	for _opt_ in "${DialogOptions[@]}"; do
		[[ ${_opt_} == "--item-help" ]] && FieldsPerItem=4 && break
	done
	local -i ItemCount=$((${#Items[@]} / FieldsPerItem))
	local -i WindowHeight=0 WindowWidth=0 MenuHeight=0
	_dialog_calc_list_size_ WindowHeight WindowWidth MenuHeight "${SubTitle}" "${Maximized}" "${ItemCount}"
	[[ ${Maximized} -eq 0 ]] && _dialog_calc_list_width_ WindowWidth "${Title}" "${SubTitle}" "${FieldsPerItem}" "${Items[@]}"

	local StyledSubTitle=""
	[[ -n ${SubTitle} ]] && StyledSubTitle="{{|Subtitle|}}${SubTitle}"

	local -i result=0
	_dialog_ "${DialogOptions[@]}" --checklist "${StyledSubTitle}" "${WindowHeight}" "${WindowWidth}" "${MenuHeight}" "${Items[@]}" || result=$?
	echo -n "${S["BS"]}" >&2
	[[ _DIALOG_EXIT_BUTTON_ -eq 1 && result -eq DIALOG_CANCEL ]] && return ${DIALOG_EXIT}
	[[ _DIALOG_EXIT_BUTTON_ -eq 1 && result -eq DIALOG_EXTRA ]] && return ${DIALOG_CANCEL}
	return ${result}
}
whiptail_checklist() {
	local Title="${1-}"
	shift || true
	local SubTitle="${1-}"
	shift || true
	local -a WhiptailOptions=()
	local -i Maximized=0

	local -i _n_=0
	_whiptail_parse_options_ WhiptailOptions Maximized _n_ "$@"
	shift "${_n_}"
	local -a Items=("$@")

	[[ -n ${Title} ]] && WhiptailOptions+=(--title "${Title}")

	local -i FieldsPerItem=3
	local Option
	local -a FilteredOptions=()
	for Option in "${WhiptailOptions[@]}"; do
		if [[ ${Option} == "--item-help" ]]; then
			FieldsPerItem=4
		else
			FilteredOptions+=("${Option}")
		fi
	done
	WhiptailOptions=("${FilteredOptions[@]}")
	local -i ItemCount=$((${#Items[@]} / FieldsPerItem))
	if [[ FieldsPerItem -eq 4 ]]; then
		_strip_helptext_in_place_ Items 4
		FieldsPerItem=3
	fi
	local -i WindowHeight=0 WindowWidth=0 MenuHeight=0
	_whiptail_calc_list_size_ WindowHeight WindowWidth MenuHeight "${SubTitle}" "${Maximized}" "${ItemCount}"
	[[ ${Maximized} -eq 0 ]] && _whiptail_calc_list_width_ WindowWidth "${Title}" "${SubTitle}" "${FieldsPerItem}" "${Items[@]}"

	local -i result=0
	_whiptail_ "${WhiptailOptions[@]}" --checklist "${SubTitle}" "${WindowHeight}" "${WindowWidth}" "${MenuHeight}" "${Items[@]}" || result=$?
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
	local -i _DIALOG_EXIT_BUTTON_=0
	_dialog_parse_options_ DialogOptions Maximized _n_ "$@"
	shift "${_n_}"
	local -a Items=("$@")

	[[ -n ${Title} ]] && DialogOptions+=(--title "{{|Title|}}${Title}")

	local -i FieldsPerItem=3
	local _opt_
	for _opt_ in "${DialogOptions[@]}"; do
		[[ ${_opt_} == "--item-help" ]] && FieldsPerItem=4 && break
	done
	local -i ItemCount=$((${#Items[@]} / FieldsPerItem))
	local -i WindowHeight=0 WindowWidth=0 MenuHeight=0
	_dialog_calc_list_size_ WindowHeight WindowWidth MenuHeight "${SubTitle}" "${Maximized}" "${ItemCount}"
	[[ ${Maximized} -eq 0 ]] && _dialog_calc_list_width_ WindowWidth "${Title}" "${SubTitle}" "${FieldsPerItem}" "${Items[@]}"

	local StyledSubTitle=""
	[[ -n ${SubTitle} ]] && StyledSubTitle="{{|Subtitle|}}${SubTitle}"

	local -i result=0
	_dialog_ "${DialogOptions[@]}" --radiolist "${StyledSubTitle}" "${WindowHeight}" "${WindowWidth}" "${MenuHeight}" "${Items[@]}" || result=$?
	echo -n "${S["BS"]}" >&2
	[[ _DIALOG_EXIT_BUTTON_ -eq 1 && result -eq DIALOG_CANCEL ]] && return ${DIALOG_EXIT}
	[[ _DIALOG_EXIT_BUTTON_ -eq 1 && result -eq DIALOG_EXTRA ]] && return ${DIALOG_CANCEL}
	return ${result}
}
whiptail_radiolist() {
	local Title="${1-}"
	shift || true
	local SubTitle="${1-}"
	shift || true
	local -a WhiptailOptions=()
	local -i Maximized=0

	local -i _n_=0
	_whiptail_parse_options_ WhiptailOptions Maximized _n_ "$@"
	shift "${_n_}"
	local -a Items=("$@")

	[[ -n ${Title} ]] && WhiptailOptions+=(--title "${Title}")

	local -i FieldsPerItem=3
	local Option
	local -a FilteredOptions=()
	for Option in "${WhiptailOptions[@]}"; do
		if [[ ${Option} == "--item-help" ]]; then
			FieldsPerItem=4
		else
			FilteredOptions+=("${Option}")
		fi
	done
	WhiptailOptions=("${FilteredOptions[@]}")
	local -i ItemCount=$((${#Items[@]} / FieldsPerItem))
	if [[ FieldsPerItem -eq 4 ]]; then
		_strip_helptext_in_place_ Items 4
		FieldsPerItem=3
	fi
	local -i WindowHeight=0 WindowWidth=0 MenuHeight=0
	_whiptail_calc_list_size_ WindowHeight WindowWidth MenuHeight "${SubTitle}" "${Maximized}" "${ItemCount}"
	[[ ${Maximized} -eq 0 ]] && _whiptail_calc_list_width_ WindowWidth "${Title}" "${SubTitle}" "${FieldsPerItem}" "${Items[@]}"

	local -i result=0
	_whiptail_ "${WhiptailOptions[@]}" --radiolist "${SubTitle}" "${WindowHeight}" "${WindowWidth}" "${MenuHeight}" "${Items[@]}" || result=$?
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
	_dialog_parse_options_ DialogOptions Maximized _n_ "$@"
	shift "${_n_}"
	local -a Items=("$@")

	[[ -n ${Title} ]] && DialogOptions+=(--title "{{|Title|}}${Title}")

	local -i FieldsPerItem=2
	local _opt_
	for _opt_ in "${DialogOptions[@]}"; do
		[[ ${_opt_} == "--item-help" ]] && FieldsPerItem=3 && break
	done
	local -i ItemCount=$((${#Items[@]} / FieldsPerItem))
	local -i WindowHeight=0 WindowWidth=0 MenuHeight=0
	_dialog_calc_list_size_ WindowHeight WindowWidth MenuHeight "${SubTitle}" "${Maximized}" "${ItemCount}"
	[[ ${Maximized} -eq 0 ]] && _dialog_calc_list_width_ WindowWidth "${Title}" "${SubTitle}" "${FieldsPerItem}" "${Items[@]}"

	local StyledSubTitle=""
	[[ -n ${SubTitle} ]] && StyledSubTitle="{{|Subtitle|}}${SubTitle}"

	local -i result=0
	_dialog_ "${DialogOptions[@]}" --inputmenu "${StyledSubTitle}" "${WindowHeight}" "${WindowWidth}" "${MenuHeight}" "${Items[@]}" || result=$?
	echo -n "${S["BS"]}" >&2
	return ${result}
}

invalid_tui_button() {
	local -i DialogButtonNumber=${1}
	local -l NoticeType=${2:-fatal}
	local DialogButton="${DIALOG_BUTTONS[DialogButtonNumber]-#${DialogButtonNumber}}"
	${NoticeType} "Unexpected dialog button '{{|ButtonName|}}${DialogButton}{{[-]}}' pressed."
}

tui_inputbox_into() {
	local -n _tibi_out_="${1}"
	assert_nameref_is_string "${1}"
	shift
	local -i result=0
	local temp_file="${TEMP_FOLDER}/${APPLICATION_NAME,,}.${FUNCNAME[0]}.$$.tmp"
	if use_dialog; then
		dialog_inputbox "$@" > "${temp_file}" || result=$?
	else
		whiptail_inputbox "$@" > "${temp_file}" || result=$?
	fi
	read -r _tibi_out_ < "${temp_file}" || true
	rm -f "${temp_file}"
	return ${result}
}

tui_menu_into() {
	local -n _tbmi_out_="${1}"
	assert_nameref_is_string "${1}"
	shift
	local -i result=0
	local temp_file="${TEMP_FOLDER}/${APPLICATION_NAME,,}.${FUNCNAME[0]}.$$.tmp"
	if use_dialog; then
		dialog_menu "$@" > "${temp_file}" || result=$?
	else
		whiptail_menu "$@" > "${temp_file}" || result=$?
	fi
	read -r _tbmi_out_ < "${temp_file}" || true
	rm -f "${temp_file}"
	return ${result}
}

tui_checklist_into_array() {
	local -n _tcia_out_="${1}"
	assert_nameref_is_array "${1}"
	shift
	local -i result=0
	local temp_file="${TEMP_FOLDER}/${APPLICATION_NAME,,}.${FUNCNAME[0]}.$$.tmp"
	if use_dialog; then
		dialog_checklist "$@" > "${temp_file}" || result=$?
	else
		whiptail_checklist "$@" > "${temp_file}" || result=$?
	fi
	readarray -t _tcia_out_ < "${temp_file}"
	rm -f "${temp_file}"
	return ${result}
}

tui_radiolist_into() {
	local -n _tbri_out_="${1}"
	assert_nameref_is_string "${1}"
	shift
	local -i result=0
	local temp_file="${TEMP_FOLDER}/${APPLICATION_NAME,,}.${FUNCNAME[0]}.$$.tmp"
	if use_dialog; then
		dialog_radiolist "$@" > "${temp_file}" || result=$?
	else
		whiptail_radiolist "$@" > "${temp_file}" || result=$?
	fi
	read -r _tbri_out_ < "${temp_file}" || true
	rm -f "${temp_file}"
	return ${result}
}
