#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

create_strip_ansi_colors_SEDSTRING() {
	# Create the search string to strip ANSI colors
	# String is saved after creation, so this is only done on the first call
	local -a ANSICOLORS=("${F[@]}" "${B[@]}" "${BD}" "${UL}" "${NC}" "${BS}")
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
	local List
	List=$(xargs <<< "$*")
	if [[ -n ${List-} ]]; then
		echo "${DC["Subtitle"]-}${List// /${DC["NC"]-} ${DC["Subtitle"]-}}${DC["NC"]-}"
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
			Result+="${Quote}${Color}${element}${NC}${Quote}${NC} "
		else
			# Otherwise, add it as is
			Result+="${Color}${element}${NC} "
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
		VisibleData+=("$(strip_ansi_colors "${item}")")
	done

	local -a ColWidths
	readarray -t ColWidths < <(longest_columns "${Cols}" "${VisibleData[@]}")

	local Separator="+"
	for ((i = 0; i < Cols; i++)); do
		local Width=${ColWidths[i]}
		local Dashes
		Dashes="$(printf "%*s" $((Width + 2)) "")"
		Separator="${Separator}${Dashes// /-}+"
	done

	echo "${Separator}"

	# Print Headings
	local RowStr="|"
	for ((c = 0; c < Cols; c++)); do
		local Item="${Headings[c]-}"
		local VisItem="${VisibleData[c]-}"
		local Width=${ColWidths[c]}
		local PadSize=$((Width - ${#VisItem}))
		local Padding
		Padding="$(printf "%*s" "${PadSize}" "")"
		RowStr="${RowStr} ${Item}${Padding} |"
	done
	echo "${RowStr}"
	echo "${Separator}"

	# Print Data
	local -i TotalItems=${#Data[@]}
	for ((i = 0; i < TotalItems; i += Cols)); do
		local RowStr="|"
		for ((c = 0; c < Cols; c++)); do
			local Idx=$((i + c))
			local Item="${Data[Idx]-}"
			local VisItem="${VisibleData[Cols + Idx]-}" # Offset by Headings count (Cols)
			local Width=${ColWidths[c]}
			local PadSize=$((Width - ${#VisItem}))
			local Padding
			Padding="$(printf "%*s" "${PadSize}" "")"
			RowStr="${RowStr} ${Item}${Padding} |"
		done
		echo "${RowStr}"
	done
	echo "${Separator}"
}

table() {
	local -i Cols=${1}
	shift
	local -a Headings=("${@:1:Cols}")
	local -a Data=("${@:Cols+1}")
	printf '%s\n' "${Data[@]}" | table_pipe "${Cols}" "${Headings[@]}"
}
