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
