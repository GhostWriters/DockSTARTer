#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

theme_table() {
    local -a ThemeList
    readarray -t ThemeList < <(find "${THEME_FOLDER}" -maxdepth 1 -type d ! -path "${THEME_FOLDER}" -printf "%f\n" | sort)
    for ThemeName in "${ThemeList[@]-}"; do
        if run_script 'theme_exists' "${ThemeName}"; then
            local ThemeDescription ThemeAuthor
            ThemeDescription="$(run_script 'theme_description' "${ThemeName}")"
            ThemeAuthor="$(run_script 'theme_author' "${ThemeName}")"
            printf '%s\t%s\t%s\n' "${ThemeName}" "${ThemeDescription}" "${ThemeAuthor}"
        fi
    done | column --table --separator $'\t' --table-columns=Theme,Description,Author
}

test_theme_table() {
    run_script 'theme_table'
}
