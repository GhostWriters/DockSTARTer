#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

theme_table() {

    local ThemeHeading="Theme"
    local DescriptionHeading="Description"
    local AuthorHeading="Author"

    local -i ThemeLength=${#ThemeHeading}
    local -i DescriptionLength=${#DescriptionHeading}
    local -i AuthorLength=${#AuthorHeading}

    local -a TableArray=()
    local -a ThemeList
    readarray -t ThemeList < <(find "${THEME_FOLDER}" -maxdepth 1 -type d ! -path "${THEME_FOLDER}" -printf "%f\n" | sort)
    for ThemeName in "${ThemeList[@]-}"; do
        if run_script 'theme_exists' "${ThemeName}"; then
            local ThemeDescription ThemeAuthor
            ThemeDescription="$(run_script 'theme_description' "${ThemeName}")"
            ThemeAuthor="$(run_script 'theme_author' "${ThemeName}")"
            ThemeLength=$((${#ThemeName} > ThemeLength ? ${#ThemeName} : ThemeLength))
            DescriptionLength=$((${#ThemeDescription} > DescriptionLength ? ${#ThemeDescription} : DescriptionLength))
            AuthorLength=$((${#ThemeAuthor} > AuthorLength ? ${#ThemeAuthor} : AuthorLength))
            TableArray+=("${ThemeName}" "${ThemeDescription}" "${ThemeAuthor}")
        fi
    done
    local ThemeLine DescriptionLine AuthorLine
    ThemeLine="$(printf %$((ThemeLength + 1))s '' | tr ' ' '-')"
    DescriptionLine="$(printf %$((DescriptionLength + 1))s '' | tr ' ' '-')"
    AuthorLine="$(printf %$((AuthorLength + 1))s '' | tr ' ' '-')"
    TableArray=("${ThemeLine}" "${DescriptionLine}" "${AuthorLine}" "${TableArray[@]}")
    printf '%s\t%s\t%s\n' "${TableArray[@]}" |
        column --table --separator $'\t' --output-separator '   ' --table-columns=Theme,Description,Author
}

test_theme_table() {
    run_script 'theme_table'
}
