#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

theme_description() {
    local ThemeName=${1-}

    local ThemeFile="${THEME_FOLDER}/${ThemeName}/${THEME_FILE_NAME}"

    echo "$(run_script 'env_get' ThemeDescription "${ThemeFile}")"
}

test_theme_description() {
    warn "CI does not test theme_description."
}
