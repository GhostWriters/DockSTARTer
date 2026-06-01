#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

create_strip_ansi_colors_SEDSTRING() {
	# Create the search string to strip ANSI colors
	# String is saved after creation, so this is only done on the first call
	local -a ANSICOLORS=("${F[@]}" "${B[@]}" "${S[@]}")
	for index in "${!ANSICOLORS[@]}"; do
		# Escape characters used by sed
		ANSICOLORS[index]=$(printf '%s' "${ANSICOLORS[index]}" | sed -E 's/[]{}()[/{}\.''''$]/\\&/g')
	done
	printf '%s' "s/$(
		IFS='|'
		printf '%s' "${ANSICOLORS[*]}"
	)//g"
}
strip_ansi_colors_SEDSTRING="$(create_strip_ansi_colors_SEDSTRING)"
readonly strip_ansi_colors_SEDSTRING
strip_ansi_colors() {
	# Strip ANSI colors
	local InputString=${1-}
	sed -E "${strip_ansi_colors_SEDSTRING}" <<< "${InputString}"
}
strip_dialog_colors() {
	# Strip Dialog colors from the arguments.  Dialog colors are in the form of '\Zc', where 'c' is any character
	local InputString=${1-}
	printf '%s' "${InputString//\\Z?/}"
}

# Take whitespace and newline delimited words and output a single line highlighted list for dialog
highlighted_list() {
	local -a ListArray
	IFS=$' \t\n\r' read -d '' -ra ListArray <<< "$*" || true
	if [[ ${#ListArray[@]} -gt 0 ]]; then
		local List
		local old_IFS="${IFS}"
		IFS=' '
		List="${ListArray[*]}"
		IFS="${old_IFS}"
		echo "{{|Subtitle|}}${List// /{{[-]}} {{|Subtitle|}}}{{[-]}}"
	fi
}

quote_elements_with_spaces() {
	local Result=''
	# Quote any arguments with spaces in them
	for element in "$@"; do
		if [[ -z ${element} || ${element} == *" "* ]]; then
			# If the element is an empty string or contains spaces, quote it
			Result+="\"${element}\" "
		else
			# Otherwise, add it as is
			Result+="${element} "
		fi
	done
	# Remove any trailing space
	Result="${Result% }"
	printf '%s\n' "${Result}"
}

custom_quote_elements_with_spaces() {
	local Quote=${1}
	local Color=${2}
	shift 2

	local Result=''
	# Quote any arguments with spaces in them
	for element in "$@"; do
		if [[ -z ${element} || ${element} == *" "* ]]; then
			# If the element is an empty string or contains spaces, quote it
			Result+="${Quote}${Color}${element}{{[-]}}${Quote}{{[-]}} "
		else
			# Otherwise, add it as is
			Result+="${Color}${element}{{[-]}} "
		fi
	done
	# Remove any trailing space
	Result="${Result% }"
	printf '%s\n' "${Result}"
}

is_true() {
	local -u Boolean=${1-}
	[[ ${Boolean} =~ ^(1|ON|TRUE|YES)$ ]]
}

is_false() {
	! is_true "${1-}"
}

string_to_bool() {
	is_true "${1-}" && echo "true" || echo "false"
}

string_to_int() {
	local val=${1:-"0"}
	if ! [[ ${val} =~ ^[0-9]+$ ]]; then
		val="0"
	fi
	echo "${val}"
}

folder_is_empty() {
	local dir=${1}
	(
		shopt -s dotglob nullglob
		set -- "${dir}"/*
		(($# == 0))
	)
}

longest_columns() {
	# 'longest_columns' int NumberOfColumns, array Elements
	if [[ ! ${1-} =~ ^[0-9]+$ || ${1} -lt 0 ]]; then
		error \
			"First argument must be a positive number."
		return 1
	fi
	local -i NumberOfCols=${1-}
	shift
	local -a Elements=("$@")
	local -i NumberOfElements=${#Elements[@]}
	local -a ColLength
	for ((col = 0; col < NumberOfCols; col += 1)); do
		ColLength[col]=0
	done
	for ((index = 0; index < NumberOfElements; index++)); do
		local -i col
		col=$((index % NumberOfCols))
		local TestValue
		TestValue=${Elements[index]}
		if [[ ${#TestValue} -gt $((ColLength[col])) ]]; then
			ColLength[col]=${#TestValue}
		fi
	done
	printf '%s\n' "${ColLength[@]}"
}

group_id() {
	# group_id string GroupName
	#
	# Returns the GroupID

	local GroupName=${1}

	if command -v getent &> /dev/null; then
		# Linux, use getent
		cut -d: -f3 < <(getent group "${GroupName}")
	elif command -v dscl &> /dev/null; then
		# MacOS, use dscl
		cut -d ' ' -f2 < <(dscl . -read /Groups/"${GroupName}" PrimaryGroupID)
	else
		warn "Unable to get group id of '${GroupName}'."
	fi
}

add_user_to_group() {
	local UserName=${1}
	local GroupName=${2}

	if sudo which usermod &> /dev/null; then
		# Linux, use usermod
		sudo usermod -aG "${GroupName}" "${UserName}"
		return
	elif command -v dseditgroup &> /dev/null; then
		# MacOS, use dseditgroup
		sudo dseditgroup -o edit -a "${UserName}" -t user "${GroupName}"
		return
	else
		return 1
	fi
}

add_group() {
	local GroupName=${1}

	if command -v getent &> /dev/null; then
		# Linux, use getent and groupadd
		if getent group "${GroupName}" &> /dev/null; then
			# Group alrady exists, nothing to do
			return 0
		fi
		sudo groupadd -f "${GroupName}"
		return
	elif command -v dseditgroup &> /dev/null; then
		# MacOS, use dscl and dseditgroup
		if dscl . -read /Groups/"${GroupName}" &> /dev/null; then
			# Group alrady exists, nothing to do
			return 0
		fi
		sudo dseditgroup -o create "${GroupName}"
		return
	fi
	return 1
}

touchfile() {
	local File=${1}
	if ! touch "${File}" &> /dev/null; then
		# If touching the file fails, try creating the parent folder and taking ownership
		local Folder
		Folder="$(dirname "${File}")"
		mkdir -p "${Folder}" &> /dev/null || sudo mkdir -p "${Folder}"
		sudo chown "${DETECTED_PUID}":"${DETECTED_PGID}" "${Folder}"
		sudo chmod a=,a+rX,u+w,g+w "${Folder}"
		touch "${File}"
	fi
}

expand_vars() {
	local String="$1"
	shift
	local -A Vars
	while (($# >= 2)); do
		Vars["$1"]="$2"
		shift 2
	done

	# Recursively expand variables
	local Changed=1
	local -i LoopCount=0
	local -i MaxLoops=10

	while [[ ${Changed} -eq 1 && ${LoopCount} -lt ${MaxLoops} ]]; do
		Changed=0
		for Key in "${!Vars[@]}"; do
			if [[ ${String} == *"\${${Key}?}"* ]]; then
				local NewString="${String//\$\{${Key}\?\}/${Vars[${Key}]}}"
				if [[ ${NewString} != "${String}" ]]; then
					String="${NewString}"
					Changed=1
				fi
			fi
			if [[ ${String} == *"\${${Key}}"* ]]; then
				local NewString="${String//\$\{${Key}\}/${Vars[${Key}]}}"
				if [[ ${NewString} != "${String}" ]]; then
					String="${NewString}"
					Changed=1
				fi
			fi
		done
		LoopCount+=1
	done
	echo "${String}"
}

replace_with_vars() {
	local String="$1"
	shift
	local -A Vars
	local -a Keys
	while (($# >= 2)); do
		Vars["$1"]="$2"
		Keys+=("$1")
		shift 2
	done

	for Key in "${Keys[@]}"; do
		local Value="${Vars[$Key]}"
		if [[ -n ${Value-} ]]; then
			local Pattern="${Value//\\/\\\\}" # Escape backslash first
			Pattern="${Pattern//\*/\\*}"      # Escape *
			Pattern="${Pattern//\?/\\?}"      # Escape ?
			Pattern="${Pattern//\[/\\[}"      # Escape [
			Pattern="${Pattern//\]/\\]}"      # Escape ]

			local Replacement="\${${Key}?}"
			String="${String//${Pattern}/${Replacement}}"
		fi
	done
	echo "${String}"
}

table_pipe() {
	local -i Cols=${1}
	shift
	local -a Headings=("${@}")

	local -a Data
	readarray -t Data

	local -a AllData=("${Headings[@]}" "${Data[@]}")
	local -a VisibleData
	for item in "${AllData[@]}"; do
		local _vs_item_
		strip_styles_into _vs_item_ "${item}"
		VisibleData+=("${_vs_item_}")
	done

	local -a ColWidths
	readarray -t ColWidths < <(longest_columns "${Cols}" "${VisibleData[@]}")

	local -A CharSet
	if is_false "${D["ui.line_characters"]-}" || in_tui_box; then
		CharSet=(
			["TopLeft"]="+"
			["TopRight"]="+"
			["BottomLeft"]="+"
			["BottomRight"]="+"
			["Horizontal"]="-"
			["Vertical"]="|"
			["Cross"]="+"
			["TLeft"]="|"
			["TRight"]="|"
			["TTop"]="-"
			["TBottom"]="-"
		)
	else
		CharSet=(
			["TopLeft"]="┌"
			["TopRight"]="┐"
			["BottomLeft"]="└"
			["BottomRight"]="┘"
			["Horizontal"]="─"
			["Vertical"]="│"
			["Cross"]="┼"
			["TLeft"]="├"
			["TRight"]="┤"
			["TTop"]="┬"
			["TBottom"]="┴"
		)
	fi

	local TopBorder="${CharSet["TopLeft"]}"
	local MiddleBorder="${CharSet["TLeft"]}"
	local BottomBorder="${CharSet["BottomLeft"]}"

	for ((i = 0; i < Cols; i++)); do
		local Width=${ColWidths[i]}
		local Dashes
		Dashes="$(printf "%*s" $((Width + 2)) "")"
		Dashes="${Dashes// /${CharSet["Horizontal"]}}"

		if ((i < Cols - 1)); then
			TopBorder+="${Dashes}${CharSet["TTop"]}"
			MiddleBorder+="${Dashes}${CharSet["Cross"]}"
			BottomBorder+="${Dashes}${CharSet["TBottom"]}"
		else
			TopBorder+="${Dashes}${CharSet["TopRight"]}"
			MiddleBorder+="${Dashes}${CharSet["TRight"]}"
			BottomBorder+="${Dashes}${CharSet["BottomRight"]}"
		fi
	done

	echo "${TopBorder}"

	# Print Headings
	local RowStr="${CharSet["Vertical"]}"
	for ((c = 0; c < Cols; c++)); do
		local Item="${Headings[c]-}"
		local VisItem="${VisibleData[c]-}"
		local Width=${ColWidths[c]}
		local PadSize=$((Width - ${#VisItem}))
		local Padding
		Padding="$(printf "%*s" "${PadSize}" "")"
		RowStr="${RowStr} ${Item}${Padding} ${CharSet["Vertical"]}"
	done
	echo "${RowStr}"
	echo "${MiddleBorder}"

	# Print Data
	local -i TotalItems=${#Data[@]}
	for ((i = 0; i < TotalItems; i += Cols)); do
		local RowStr="${CharSet["Vertical"]}"
		for ((c = 0; c < Cols; c++)); do
			local Idx=$((i + c))
			local Item="${Data[Idx]-}"
			local VisItem="${VisibleData[Cols + Idx]-}" # Offset by Headings count (Cols)
			local Width=${ColWidths[c]}
			local PadSize=$((Width - ${#VisItem}))
			local Padding
			Padding="$(printf "%*s" "${PadSize}" "")"
			RowStr="${RowStr} ${Item}${Padding} ${CharSet["Vertical"]}"
		done
		echo "${RowStr}"
	done
	echo "${BottomBorder}"
}

table() {
	local -i Cols=${1}
	shift
	local -a Headings=("${@:1:Cols}")
	local -a Data=("${@:Cols+1}")
	if use_tui_box || [[ -t 1 ]]; then
		printf '%s\n' "${Data[@]}" | table_pipe "${Cols}" "${Headings[@]}" | resolve_strings C
	else
		# Captured/Piped call: Output RAW TAGS
		# (This lets notice handle the resolution later)
		printf '%s\n' "${Data[@]}" | table_pipe "${Cols}" "${Headings[@]}"
	fi
}

wordwrap_pipe() {
	local -i Width=${1:-80}

	local Word
	local Line=""

	while IFS=$' \t\n' read -r -a Words; do
		for Word in "${Words[@]}"; do
			if ((${#Line} > 0 && ${#Line} + 1 + ${#Word} > Width)); then
				printf '%s\n' "${Line}"
				Line="${Word}"
			else
				Line="${Line:+$Line }${Word}"
			fi
		done
	done
	[[ -n ${Line} ]] && printf '%s\n' "${Line}"
}

wordwrap() {
	local String=${1}
	local -i Width=${2:-80}

	wordwrap_pipe "${Width}" <<< "${String}"
}

get_toml_val() {
	# get_toml_val FILE SECTION.KEY
	local result
	get_toml_val_into result "${1-}" "${2-}" || return 1
	printf '%s\n' "${result}"
}

get_toml_val_into() {
	# get_toml_val_into OutVar FILE SECTION.KEY
	local -n _gtvi_out_="${1}"
	assert_nameref_is_string "${1}"
	local _gtvi_file_=${2-}
	local _gtvi_section_key_="${3-}"
	local _gtvi_section_="${_gtvi_section_key_%%.*}"
	local _gtvi_target_key_="${_gtvi_section_key_#*.}"
	local _gtvi_current_section_=""

	local _gtvi_key_ _gtvi_val_
	while IFS='= ' read -r _gtvi_key_ _gtvi_val_ || [[ -n ${_gtvi_key_}${_gtvi_val_} ]]; do
		if [[ ${_gtvi_key_} =~ ^\[(.*)\]$ ]]; then
			_gtvi_current_section_="${BASH_REMATCH[1]}"
			continue
		fi
		if [[ ${_gtvi_current_section_} == "${_gtvi_section_}" && ${_gtvi_key_} == "${_gtvi_target_key_}" ]]; then
			_gtvi_val_="${_gtvi_val_#"${_gtvi_val_%%[![:space:]]*}"}"
			_gtvi_val_="${_gtvi_val_%"${_gtvi_val_##*[![:space:]]}"}"
			if [[ ${_gtvi_val_} == \"*\" ]]; then
				_gtvi_val_="${_gtvi_val_#\"}"
				_gtvi_val_="${_gtvi_val_%\"}"
			elif [[ ${_gtvi_val_} == \'*\' ]]; then
				_gtvi_val_="${_gtvi_val_#\'}"
				_gtvi_val_="${_gtvi_val_%\'}"
			else
				_gtvi_val_="${_gtvi_val_%%#*}"
				_gtvi_val_="${_gtvi_val_%"${_gtvi_val_##*[![:space:]]}"}"
			fi
			_gtvi_out_="${_gtvi_val_}"
			return 0
		fi
	done < "${_gtvi_file_}"

	return 1
}

get_ini_val() {
	# get_ini_val VarFile VarName
	local result
	get_ini_val_into result "${1-}" "${2-}" || return 1
	printf '%s\n' "${result}"
}

get_ini_val_into() {
	# get_ini_val_into OutVar VarFile VarName
	local -n _givi_out_="${1}"
	assert_nameref_is_string "${1}"
	local _givi_ConfigFile_=${2-}
	local _givi_VarName_=${3-}

	if [[ -z ${_givi_VarName_} || -z ${_givi_ConfigFile_} || ! -f ${_givi_ConfigFile_} ]]; then
		return 1
	fi

	local _givi_Line_ _givi_Val_="" _givi_Found_=false
	while IFS= read -r _givi_Line_ || [[ -n ${_givi_Line_} ]]; do
		[[ ${_givi_Line_} =~ ^[[:space:]]*# ]] && continue
		[[ -z ${_givi_Line_} ]] && continue
		if [[ ${_givi_Line_} =~ ^[[:space:]]*${_givi_VarName_}[[:space:]]*= ]]; then
			local _givi_Key_="${_givi_Line_%%=*}"
			local _givi_Value_="${_givi_Line_#*=}"
			_givi_Key_="${_givi_Key_#"${_givi_Key_%%[![:space:]]*}"}"
			_givi_Key_="${_givi_Key_%"${_givi_Key_##*[![:space:]]}"}"
			if [[ ${_givi_Key_} == "${_givi_VarName_}" ]]; then
				_givi_Val_="${_givi_Value_}"
				_givi_Found_=true
			fi
		fi
	done < "${_givi_ConfigFile_}"

	if [[ ${_givi_Found_} == false ]]; then
		return 1
	fi

	_givi_Val_="${_givi_Val_#"${_givi_Val_%%[![:space:]]*}"}"
	_givi_Val_="${_givi_Val_%"${_givi_Val_##*[![:space:]]}"}"

	if [[ ${_givi_Val_} == \'*\' ]]; then
		_givi_Val_="${_givi_Val_#\'}"
		_givi_Val_="${_givi_Val_%\'}"
	elif [[ ${_givi_Val_} == \"*\" ]]; then
		_givi_Val_="${_givi_Val_#\"}"
		_givi_Val_="${_givi_Val_%\"}"
	fi

	_givi_out_="${_givi_Val_}"
	return 0
}

get_ini_val_string() {
	local result
	get_ini_val_string_into result "${1-}" "${2-}" || return 1
	printf '%s\n' "${result}"
}

get_ini_val_string_into() {
	local -n _givsi_out_="${1}"
	assert_nameref_is_string "${1}"
	local _givsi_val_
	if get_ini_val_into _givsi_val_ "${2-}" "${3-}"; then
		_givsi_out_="${_givsi_val_}"
		return 0
	fi
	return 1
}

get_ini_val_bool() {
	# get_ini_val_bool FILE KEY
	local result
	get_ini_val_bool_into result "${1-}" "${2-}" || return 1
	printf '%s\n' "${result}"
}

get_ini_val_bool_into() {
	local -n _givbi_out_="${1}"
	assert_nameref_is_string "${1}"
	local _givbi_val_
	if get_ini_val_into _givbi_val_ "${2-}" "${3-}"; then
		is_true "${_givbi_val_}" && _givbi_out_="true" || _givbi_out_="false"
		return 0
	fi
	return 1
}

set_toml_val() {
	# set_toml_val FILE SECTION.KEY VALUE
	# Creates or updates KEY = "VALUE" within [SECTION] in FILE.
	# Creates the file, section, or key if any do not exist.
	local file=${1-}
	local section="${2%%.*}"
	local target_key="${2#*.}"
	local new_val=${3-}

	if [[ ! -f ${file} ]]; then
		touchfile "${file}"
	fi

	local new_line="${target_key} = ${new_val}"

	local -a content=()
	while IFS= read -r line || [[ -n ${line} ]]; do
		content+=("${line}")
	done < "${file}"

	local -i n=${#content[@]}
	local -i in_section=0
	local -i section_found=0
	local -i key_written=0
	local -a output=()

	local -i i
	for ((i = 0; i < n; i++)); do
		local line="${content[i]}"
		if [[ ${line} =~ ^\[(.+)\]$ ]]; then
			if [[ ${in_section} -eq 1 && ${key_written} -eq 0 ]]; then
				# Leaving our section without finding the key: insert it now
				output+=("${new_line}")
				key_written=1
			fi
			in_section=0
			if [[ ${BASH_REMATCH[1]} == "${section}" ]]; then
				in_section=1
				section_found=1
			fi
		elif [[ ${in_section} -eq 1 && ${key_written} -eq 0 ]]; then
			# Check if this line contains our key
			if [[ ${line} =~ ^[[:space:]]*${target_key}[[:space:]]*= ]]; then
				if [[ ${new_line} == "${line}" ]]; then
					return 0 # Value already set to what we want it to be
				fi
				output+=("${new_line}")
				key_written=1
				continue # drop the old line
			fi
		fi
		output+=("${line}")
	done

	# Handle key not found at end of file while still in section
	if [[ ${in_section} -eq 1 && ${key_written} -eq 0 ]]; then
		output+=("${new_line}")
	fi

	# Handle section not found: append section and key at end of file
	if [[ ${section_found} -eq 0 ]]; then
		if [[ ${#output[@]} -gt 0 && -n ${output[-1]} ]]; then
			output+=("")
		fi
		output+=("[${section}]")
		output+=("${new_line}")
	fi

	printf '%s\n' "${output[@]}" > "${file}" ||
		fatal \
			"Failed to write to '{{|File|}}${file}{{[-]}}'."
}

get_toml_val_string() {
	# get_toml_val_string FILE SECTION.KEY
	local result
	get_toml_val_string_into result "${1-}" "${2-}" || return 1
	printf '%s\n' "${result}"
}

get_toml_val_string_into() {
	local -n _gtvsi_out_="${1}"
	assert_nameref_is_string "${1}"
	local _gtvsi_val_
	if get_toml_val_into _gtvsi_val_ "${2-}" "${3-}"; then
		_gtvsi_out_="${_gtvsi_val_}"
		return 0
	fi
	return 1
}

set_toml_val_string() {
	# set_toml_val FILE SECTION.KEY VALUE
	# Creates or updates KEY = "VALUE" within [SECTION] in FILE.
	# Creates the file, section, or key if any do not exist.
	local file=${1-}
	local section="${2%%.*}"
	local target_key="${2#*.}"
	local new_val=${3-}

	# If the string contains single quotes, we MUST use double quotes
	if [[ ${new_val} == *"'"* ]]; then
		# Escape double quotes and wrap in double quotes
		new_val="\"${new_val//\"/\\\"}\""
	else
		# Use clean single quotes for everything else
		new_val="'${new_val}'"
	fi

	set_toml_val "${file}" "${section}.${target_key}" "${new_val}"
}

get_toml_val_bool() {
	# get_toml_val_bool FILE SECTION.KEY
	local result
	get_toml_val_bool_into result "${1-}" "${2-}" || return 1
	printf '%s\n' "${result}"
}

get_toml_val_bool_into() {
	local -n _gtvbi_out_="${1}"
	assert_nameref_is_string "${1}"
	local _gtvbi_val_
	if get_toml_val_into _gtvbi_val_ "${2-}" "${3-}"; then
		is_true "${_gtvbi_val_}" && _gtvbi_out_="true" || _gtvbi_out_="false"
		return 0
	fi
	return 1
}

set_toml_val_bool() {
	# set_toml_val FILE SECTION.KEY VALUE
	# Creates or updates KEY = "VALUE" within [SECTION] in FILE.
	# Creates the file, section, or key if any do not exist.
	local file=${1-}
	local section_key="${2-}"
	local new_val=${3-}

	set_toml_val "${file}" "${section_key}" "$(string_to_bool "${new_val}")"
}

get_toml_val_int() {
	# get_toml_val_int FILE SECTION.KEY
	# Returns the value of KEY within [SECTION] in FILE, normalized to an integer.
	local file=${1-}
	local section_key="${2-}"

	local Value
	if Value="$(get_toml_val "${file}" "${section_key}")"; then
		string_to_int "${Value}"
		return 0
	fi

	# Key or section not found
	return 1
}

set_toml_val_int() {
	# set_toml_val FILE SECTION.KEY VALUE
	# Creates or updates KEY = "VALUE" within [SECTION] in FILE.
	# Creates the file, section, or key if any do not exist.
	local file=${1-}
	local section_key="${2-}"
	local new_val=${3-}

	set_toml_val "${file}" "${section_key}" "$(string_to_int "${new_val}")"
}

hrx_extract_file() {
	# hrx_extract_file ArchiveFile InternalPath DestFile
	# Extracts a named file from an HRX archive to DestFile.
	# The boundary is auto-detected from the first line of the archive.
	local archive=${1-}
	local internal_path=${2-}
	local dest=${3-}
	local boundary="" capturing=0
	local -a lines=()
	while IFS= read -r line || [[ -n ${line} ]]; do
		if [[ -z ${boundary} ]]; then
			if [[ ${line} =~ ^(<[=]+>)[[:space:]] ]]; then
				boundary="${BASH_REMATCH[1]}"
			else
				continue
			fi
		fi
		if [[ ${line} == "${boundary} "* ]]; then
			[[ ${capturing} -eq 1 ]] && break
			[[ ${line#"${boundary} "} == "${internal_path}" ]] && capturing=1
			continue
		fi
		[[ ${capturing} -eq 1 ]] && lines+=("${line}")
	done < "${archive}"
	[[ ${#lines[@]} -gt 0 ]] && printf '%s\n' "${lines[@]}" > "${dest}"
}

hrx_env_get() {
	# hrx_env_get ArchiveFile InternalPath VarName
	# Returns the value of VarName from a KEY=VALUE file within an HRX archive.
	# The boundary is auto-detected from the first line of the archive.
	local archive=${1-}
	local internal_path=${2-}
	local var_name=${3-}
	local boundary="" capturing=0 found_val=""
	while IFS= read -r line || [[ -n ${line} ]]; do
		if [[ -z ${boundary} ]]; then
			if [[ ${line} =~ ^(<[=]+>)[[:space:]] ]]; then
				boundary="${BASH_REMATCH[1]}"
			else
				continue
			fi
		fi
		if [[ ${line} == "${boundary} "* ]]; then
			[[ ${capturing} -eq 1 ]] && break
			[[ ${line#"${boundary} "} == "${internal_path}" ]] && capturing=1
			continue
		fi
		if [[ ${capturing} -eq 1 ]]; then
			[[ -z ${line} || ${line} =~ ^[[:space:]]*# ]] && continue
			if [[ ${line} =~ ^[[:space:]]*${var_name}[[:space:]]*= ]]; then
				local val="${line#*=}"
				val="${val#"${val%%[! ]*}"}"
				val="${val%"${val##*[! ]}"}"
				if [[ ${val} == \"*\" ]]; then
					val="${val#\"}"
					val="${val%\"}"
				elif [[ ${val} == \'*\' ]]; then
					val="${val#\'}"
					val="${val%\'}"
				fi
				found_val="${val}"
			fi
		fi
	done < "${archive}"
	printf '%s\n' "${found_val}"
}

get_toml_section_key_list() {
	# get_toml_section_key_list FILE SECTION
	# Returns a list of all keys within [SECTION] in FILE.
	local file=${1-}
	local section=${2-}
	local current_section=""

	while IFS='= ' read -r key val || [[ -n ${key}${val} ]]; do
		if [[ ${key} =~ ^\[(.*)\]$ ]]; then
			current_section="${BASH_REMATCH[1]}"
			continue
		fi

		if [[ ${current_section} == "${section}" && -n ${key} && -n ${val} ]]; then
			printf '%s\n' "${key}"
		fi
	done < "${file}"
}

hrx_toml_get() {
	# hrx_toml_get ArchiveFile InternalPath SECTION.KEY
	local _htg_result_
	hrx_toml_get_into _htg_result_ "${1-}" "${2-}" "${3-}"
	printf '%s\n' "${_htg_result_}"
}

hrx_toml_get_into() {
	# hrx_toml_get_into OutVar ArchiveFile InternalPath SECTION.KEY
	local -n _htgi_out_="${1}"
	assert_nameref_is_string "${1}"
	local _htgi_archive_="${2-}"
	local _htgi_internal_path_="${3-}"
	local _htgi_section_key_="${4-}"
	local _htgi_section_="${_htgi_section_key_%%.*}"
	local _htgi_target_key_="${_htgi_section_key_#*.}"
	local _htgi_boundary_="" _htgi_capturing_=0 _htgi_current_section_="" _htgi_found_val_=""

	local _htgi_line_
	while IFS= read -r _htgi_line_ || [[ -n ${_htgi_line_} ]]; do
		if [[ -z ${_htgi_boundary_} ]]; then
			if [[ ${_htgi_line_} =~ ^(<[=]+>)[[:space:]] ]]; then
				_htgi_boundary_="${BASH_REMATCH[1]}"
			else
				continue
			fi
		fi
		if [[ ${_htgi_line_} == "${_htgi_boundary_} "* ]]; then
			[[ ${_htgi_capturing_} -eq 1 ]] && break
			[[ ${_htgi_line_#"${_htgi_boundary_} "} == "${_htgi_internal_path_}" ]] && _htgi_capturing_=1
			continue
		fi
		if [[ ${_htgi_capturing_} -eq 1 ]]; then
			[[ ${_htgi_line_} =~ ^[[:space:]]*# ]] && continue
			[[ ${_htgi_line_} =~ ^[[:space:]]*$ ]] && continue
			if [[ ${_htgi_line_} =~ ^\[(.*)\]$ ]]; then
				_htgi_current_section_="${BASH_REMATCH[1]}"
				continue
			fi
			if [[ ${_htgi_current_section_} == "${_htgi_section_}" && ${_htgi_line_} == *[[:space:]]*=[[:space:]]* ]]; then
				local _htgi_key_="${_htgi_line_%%=*}"
				local _htgi_val_="${_htgi_line_#*=}"
				_htgi_key_="${_htgi_key_#"${_htgi_key_%%[![:space:]]*}"}"
				_htgi_key_="${_htgi_key_%"${_htgi_key_##*[![:space:]]}"}"
				if [[ ${_htgi_key_} == "${_htgi_target_key_}" ]]; then
					_htgi_val_="${_htgi_val_#"${_htgi_val_%%[![:space:]]*}"}"
					_htgi_val_="${_htgi_val_%"${_htgi_val_##*[![:space:]]}"}"
					if [[ ${_htgi_val_} == \"*\" ]]; then
						_htgi_val_="${_htgi_val_#\"}"
						_htgi_val_="${_htgi_val_%\"}"
					elif [[ ${_htgi_val_} == \'*\' ]]; then
						_htgi_val_="${_htgi_val_#\'}"
						_htgi_val_="${_htgi_val_%\'}"
					else
						_htgi_val_="${_htgi_val_%%#*}"
						_htgi_val_="${_htgi_val_%"${_htgi_val_##*[![:space:]]}"}"
					fi
					_htgi_found_val_="${_htgi_val_}"
				fi
			fi
		fi
	done < "${_htgi_archive_}"
	_htgi_out_="${_htgi_found_val_}"
}
