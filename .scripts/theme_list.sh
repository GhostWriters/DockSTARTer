#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

theme_list() {
    local -a ThemeList
    readarray -t ThemeList < <(find "${THEME_FOLDER}" -maxdepth 1 -type d ! -path "${THEME_FOLDER}" -printf "%f\n" | sort)
    for ThemeName in "${ThemeList[@]-}"; do
        if run_script 'theme_exists' "${ThemeName}"; then
            echo "${ThemeName}"
        fi
    done
}

test_theme_list() {
    run_script 'theme_list'
}
