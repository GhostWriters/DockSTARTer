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
        if [[ ${element} == *" "* ]]; then
            # If the element contains spaces, quote it
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

is_true() {
    local -u Boolean=${1-}
    [[ ${Boolean} =~ ^(1|ON|TRUE|YES)$ ]]
}

is_false() {
    ! is_true "${1-}"
}

longest_columns() {
    # 'longest_columns' int NumberOfColumns, array Elements
    if [[ ! ${1-} =~ ^[0-9]+$ || ${1} -lt 0 ]]; then
        error "First argument must be a positive number."
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

# Version Functions
# https://stackoverflow.com/questions/4023830/how-to-compare-two-strings-in-dot-separated-version-format-in-bash#comment92693604_4024263
vergte() { printf '%s\n%s' "${2}" "${1}" | sort -C -V; }
vergt() { ! vergte "${2}" "${1}"; }
verlte() { printf '%s\n%s' "${1}" "${2}" | sort -C -V; }
verlt() { ! verlte "${2}" "${1}"; }
