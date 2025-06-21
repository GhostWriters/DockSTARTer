#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

theme_exists() {
    local ThemeName=${1-}

    local ThemeFolder="${THEME_FOLDER}/${ThemeName}"
    local ThemeFile="${ThemeFolder}/${THEME_FILE_NAME}"
    local DialogFile="${ThemeFolder}/${DIALOGRC_NAME}"

    [[ -f ${ThemeFile} && -f ${DialogFile} ]]
}

test_theme_exists() {
    warn "CI does not test theme_exists."
}
