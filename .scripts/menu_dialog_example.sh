#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_dialog_example() {
    local Title=''
    for TitleStyle in Title TitleSuccess TitleWarning TitleError TitleQuestion; do
        if [[ -n ${Title-} ]]; then
            Title+=' '
        fi
        Title+="${DC["${TitleStyle}"]}${TitleStyle}${DC[NC]}"
    done
    local ThemeName ThemeDescription ThemeAuthor
    ThemeName="$(run_script 'theme_name')"
    ThemeDescription="$(run_script 'theme_description' "${ThemeName}")"
    ThemeName="$(run_script 'theme_author' "${ThemeName}")"

    DialogText=''
    DialogText+="${DC["Subtitle"]}Applied theme ${ThemeName}${DC[NC]}\n"
    DialogText+="  ${DC["CommandLine"]}ds --theme ${ThemeName}${DC[NC]}\n"
    DialogText+="\n"
    DialogText+="        Theme: ${DC[Heading]}${ThemeName}${DC[NC]}\n"
    DialogText+="               ${DC["HeadingAppDescription"]}${ThemeDescription}${DC[NC]}\n"
    DialogText+="\n"
    DialogText+=" Theme Author: ${DC[Heading]}${ThemeAuthor}${DC[NC]}\n"
    DialogText+="\n"
    DialogText+="Final Heading: ${DC["HeadingValue"]}AppName${DC[NC]}"
    DialogText+=" ${DC["HeadingTag"]}[*HeadingTag*]${DC[NC]} ${DC["HeadingTag"]}(HeadingTag)${DC[NC]}\n"
    DialogText+="\n"
    DialogText+="     Key Caps:\n"
    DialogText+="               ${DC["KeyCap"]}[up]${DC[NC]} ${DC["KeyCap"]}[down]${DC[NC]} ${DC["KeyCap"]}[left]${DC[NC]} ${DC["KeyCap"]}[right]${DC[NC]}\n"
    DialogText+="\n"
    DialogText+="Normal text\n"
    DialogText+="${DC["Highlight"]}Highlighted text${DC[NC]}\n"

    local -a DialogOptions=(
        "" ""
        "BuiltInApp" "Built In App Description"
        "UserDefinedApp" "${DC["ListAppUserDefined"]}User Defined App Description"
        "" ""
        "Variable File Heading" "${DC["LineHeading"]}*** ${COMPOSE_ENV} ***"
        "Variable File Comment" "${DC["LineComment"]}### A comment in the variable file"
        "Variable File Other" "${DC["LineOther"]}Any other line in the file"
        "Variable File Variable" "${DC["LineVar"]}VarName='Default Value'"
        "Variable File Mofified" "${DC["LineModifiedVar"]}VarName='Modified Value'"
        "Variable File Add" "${DC["LineAddVariable"]}<ADD VARIABLE>"
    )
    local -a MenuDialog=(
        --stdout
        --title "${Title}"
        --ok-label "Select"
        --cancel-label "Done"
        --menu "${DialogText}"
        0 0
        0
        "${DialogOptions[@]}"
    )

    dialog "${MenuDialog[@]}" > /dev/null || true
}

test_menu_dialog_example() {
    warn "CI does not test theme_exists."
}
