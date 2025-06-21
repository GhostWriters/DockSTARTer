#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

theme_list() {
    local -a ThemeList
    readarray -t ThemeList < <(find "${THEME_FOLDER}" -maxdepth 1 -type d ! -path "${THEME_FOLDER}" -printf "%f\n" | sort)
    for ThemeName in "${ThemeList[@]-}"; do
        local ThemeFile="${THEME_FOLDER}/${ThemeName}/${THEME_FILE_NAME}"
        local DialogFile="${THEME_FOLDER}/${ThemeName}/${DIALOGRC_NAME}"
        if [[ -f ${ThemeFile} && -f ${DialogFile} ]]; then
            echo "${ThemeName}"
        fi
    done
}

test_theme_list() {
    run_script 'theme_list'
}
