#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_dialog_example() {
    local Message=${1-}

    local Title=''
    for TitleStyle in Title TitleSuccess TitleWarning TitleError TitleQuestion; do
        if [[ -n ${Title-} ]]; then
            Title+=' '
        fi
        Title+="${DC["${TitleStyle}"]}${TitleStyle}${DC[NC]}"
    done
    DialogText=''
    DialogText+="${DC["Subtitle"]}${Message}${DC[NC]}\n"
    DialogText+="  ${DC["CommandLine"]}Command Line Text${DC[NC]}\n"
    DialogText+="\n"
    DialogText+="${DC["KeyCap"]}[up]${DC[NC]} ${DC["KeyCap"]}[down]${DC[NC]} ${DC["KeyCap"]}[left]${DC[NC]} ${DC["KeyCap"]}[right]${DC[NC]}\n"
    DialogText+="\n"
    DialogText+="Application: ${DC[Heading]}AppName${DC[NC]} ${DC[HeadingTag]}(User Defined)${DC[NC]}\n"
    DialogText+="             ${DC["HeadingAppDescription"]}Application Description${DC[NC]}\n"
    DialogText+="\n"
    DialogText+="   Variable: ${DC["HeadingValue"]}VarName${DC[NC]} ${DC["HeadingTag"]}(User Defined)${DC[NC]}\n"
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
