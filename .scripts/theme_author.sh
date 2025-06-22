#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

theme_author() {
    local ThemeName=${1-}

    if [[ -z ${ThemeName} ]]; then
        ThemeName="$(run_script 'theme_name')"
    fi
    local ThemeFile="${THEME_FOLDER}/${ThemeName}/${THEME_FILE_NAME}"

    run_script 'env_get' ThemeAuthor "${ThemeFile}"
}

test_theme_author() {
    run_script 'apply_theme'
    run_script 'theme_author'
}
