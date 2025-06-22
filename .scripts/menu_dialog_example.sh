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
    DialogText+="${DC["KeyCap"]}[up]${DC[NC]} [down]${DC[NC]} [left]${DC[NC]} [right]${DC[NC]}\n"
    DialogText+="\n"
    DialogText+="Application: ${DC[Heading]}AppName${DC[NC]} ${DC[HeadingTag]}(User Defined)${DC[NC]}\n"
    DialogText+="             ${DC["HeadingAppDescription"]}Application Description${DC[NC]}\n"
    DialogText+="\n"
    DialogText+="   Variable: ${DC["HeadingValue"]}VarName${DC[NC]} ${DC["HeadingTag"]}(User Defined)${DC[NC]}\n"
    DialogText+="\n"
    DialogText+="Normal text\n"
    DialogText+="${DC["Highlight"]}Highlighted text${DC[NC]}\n"

    dialog_message "${Title}" "${DialogText}"
}

test_menu_dialog_example() {
    warn "CI does not test theme_exists."
}
