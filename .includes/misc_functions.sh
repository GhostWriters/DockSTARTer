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

# Version Functions
# https://stackoverflow.com/questions/4023830/how-to-compare-two-strings-in-dot-separated-version-format-in-bash#comment92693604_4024263
vergte() { printf '%s\n%s' "${2}" "${1}" | sort -C -V; }
vergt() { ! vergte "${2}" "${1}"; }
verlte() { printf '%s\n%s' "${1}" "${2}" | sort -C -V; }
verlt() { ! verlte "${2}" "${1}"; }
