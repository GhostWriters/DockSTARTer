#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_dialog_example() {
    local Message=${1-}
    local CommandLine=${2-}

    local ThemeName ThemeDescription ThemeAuthor
    ThemeName="$(run_script 'theme_name')"
    ThemeDescription="$(run_script 'theme_description' "${ThemeName}")"
    ThemeAuthor="$(run_script 'theme_author' "${ThemeName}")"

    if [[ -z ${Message} ]]; then
        Message="Applied theme ${ThemeName}"
    fi
    if [[ -z ${CommandLine} ]]; then
        CommandLine="${APPLICATION_COMMAND} --theme"
    fi

    local Title=''
    for TitleStyle in Title TitleSuccess TitleWarning TitleError TitleQuestion; do
        if [[ -n ${Title-} ]]; then
            Title+=' '
        fi
        Title+="${DC["${TitleStyle}"]-}${TitleStyle}${DC["NC"]-}"
    done

    DialogText=''
    DialogText+="${DC["Subtitle"]-}${Message} and displaying sample${DC["NC"]-}\n"
    DialogText+="  ${DC["CommandLine"]-}${CommandLine}${DC["NC"]-}\n"
    DialogText+="\n"
    DialogText+="        Theme: ${DC["Heading"]-}${ThemeName}${DC["NC"]-}\n"
    DialogText+="               ${DC["HeadingAppDescription"]-}${ThemeDescription}${DC["NC"]-}\n"
    DialogText+="\n"
    DialogText+=" Theme Author: ${DC["Heading"]-}${ThemeAuthor}${DC["NC"]-}\n"
    DialogText+="\n"
    DialogText+="Final Heading: ${DC["HeadingValue"]-}AppName${DC["NC"]-}"
    DialogText+=" ${DC["HeadingTag"]-}[*HeadingTag*]${DC["NC"]-} ${DC["HeadingTag"]-}(HeadingTag)${DC["NC"]-}\n"
    DialogText+="\n"
    DialogText+="     Key Caps: ${DC["KeyCap"]-}[up]${DC["NC"]-} ${DC["KeyCap"]-}[down]${DC["NC"]-} ${DC["KeyCap"]-}[left]${DC["NC"]-} ${DC["KeyCap"]-}[right]${DC["NC"]-}\n"
    DialogText+="\n"
    DialogText+="Normal text\n"
    DialogText+="${DC["Highlight"]-}Highlighted text${DC["NC"]-}\n"

    local Helpline="This is a sample help line with ${DC["Highlight"]-}highlighted${DC["NC"]-} text."

    COLUMNS=$(tput cols)
    LINES=$(tput lines)
    local -i MenuTextLines
    MenuTextLines="$(
        _dialog_ \
            --output-fd 1 \
            --print-text-size \
            "${DialogText}" \
            "$((LINES - DC["WindowRowsAdjust"]))" "$((COLUMNS - DC["WindowColsAdjust"]))" |
            cut -d ' ' -f 1
    )"
    local -a DialogOptions=(
        "" "" "${Helpline}"
        "BuiltInApp" "Built In App Description" "${Helpline}"
        "UserDefinedApp" "${DC["ListAppUserDefined"]-}User Defined App Description" "${Helpline}"
        "" "" "${Helpline}"
        "Variable File Heading" "${DC["LineHeading"]-}*** ${COMPOSE_ENV} ***" "${Helpline}"
        "Variable File Comment" "${DC["LineComment"]-}### A comment in the variable file" "${Helpline}"
        "Variable File Other" "${DC["LineOther"]-}Any other line in the file" "${Helpline}"
        "Variable File Variable" "${DC["LineVar"]-}VarName='Default Value'" "${Helpline}"
        "Variable File Mofified" "${DC["LineModifiedVar"]-}VarName='Modified Value'" "${Helpline}"
        "Variable File Add" "${DC["LineAddVariable"]-}<ADD VARIABLE>" "${Helpline}"
        "" "" "${Helpline}"
        "" "" "${Helpline}"
        "" "" "${Helpline}"
        "" "" "${Helpline}"
        "" "" "${Helpline}"
        "" "" "${Helpline}"
        "" "" "${Helpline}"
        "" "" "${Helpline}"
        "" "" "${Helpline}"
        "" "" "${Helpline}"
    )
    local -a MenuDialog=(
        --output-fd 1
        --title "${Title}"
        --ok-label "Select"
        --cancel-label "Done"
        --item-help
        --menu "${DialogText}"
        "$((LINES - DC["WindowRowsAdjust"]))" "$((COLUMNS - DC["WindowColsAdjust"]))"
        "$((LINES - DC["TextRowsAdjust"] - MenuTextLines))"
        "${DialogOptions[@]}"
    )

    _dialog_ "${MenuDialog[@]}" > /dev/null || true
}

test_menu_dialog_example() {
    warn "CI does not test theme_exists."
}
