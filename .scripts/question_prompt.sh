#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

question_prompt() {
    local Default=${1-Y}
    Default=${Default^^:0:1}
    if [[ ${Default} != Y && ${Default} != N ]]; then
        Default=""
    fi
    local Question=${2-}
    local Title=${3-$APPLICATION_NAME}
    local Override=${4-}
    Override=${Override^^:0:1}
    local YesButton=${5-Yes}
    local NoButton=${6-No}

    if [[ ${Override} != Y && ${Override} != N ]]; then
        Override=""
    fi

    local YN
    if [[ ${CI-} == true ]]; then
        YN=${Default:-Y}
    elif [[ -n ${Override-} ]]; then
        YN="${Override}"
    elif use_dialog_box; then
        local DIALOG_DEFAULT
        if [[ ${Default} == "N" ]]; then
            DIALOG_DEFAULT="--defaultno"
        fi
        local NoticeQuestion
        NoticeQuestion=$(strip_dialog_colors "${Question}")
        local DialogQuestion
        DialogQuestion=$(strip_ansi_colors "${Question}")
        while true; do
            local YNPrompt
            if [[ ${Default} == Y ]]; then
                YNPrompt='[Yn]'
            elif [[ ${Default} == N ]]; then
                YNPrompt='[yN]'
            else
                YNPrompt='[YN]'
            fi
            notice "${NoticeQuestion}" &> /dev/null
            notice "${YNPrompt}" &> /dev/null
            # shellcheck disable=SC2206 # (warning): Quote to prevent word splitting/globbing, or split robustly with mapfile or read -a.
            local -a YesNoDialog=(
                --output-fd 1
                --no-collapse
                --yes-label "${YesButton}"
                --no-label "${NoButton}"
                --title "${DC[TitleQuestion]}${Title}${DC[NC]}"
                ${DIALOG_DEFAULT-}
                --yesno "${DC[NC]}${DialogQuestion}${DC[NC]}"
                "$((LINES - DC["WindowRowsAdjust"]))" "$((COLUMNS - DC["WindowColsAdjust"]))"
            )
            local -i YesNoDialogButtonPressed=0
            _dialog_ "${YesNoDialog[@]}" || YesNoDialogButtonPressed=$?
            case ${DIALOG_BUTTONS[YesNoDialogButtonPressed]-} in
                OK)
                    YN="Y"
                    notice "Answered: Yes" &> /dev/null
                    break
                    ;;
                CANCEL | ESC)
                    YN="N"
                    notice "Answered: No" &> /dev/null
                    break
                    ;;
                *)
                    if [[ -n ${DIALOG_BUTTONS[YesNoDialogButtonPressed]-} ]]; then
                        fatal "Unexpected dialog button '${DIALOG_BUTTONS[YesNoDialogButtonPressed]}' pressed in question_prompt."
                    else
                        fatal "Unexpected dialog button value '${YesNoDialogButtonPressed}' pressed in question_prompt."
                    fi
                    ;;
            esac
        done
    elif [[ ${PROMPT:-CLI} == "CLI" ]]; then
        local YNPrompt
        if [[ ${Default} == Y ]]; then
            YNPrompt="[Yn]"
        elif [[ ${Default} == N ]]; then
            YNPrompt="[yN]"
        else
            YNPrompt="[YN]"
        fi
        NoticeQuestion=$(strip_dialog_colors "${Question}")
        notice "${NoticeQuestion}"
        notice "${YNPrompt}"
        while true; do
            read -rsn1 YN < /dev/tty
            YN=${YN^^}
            case ${YN} in
                [YN])
                    break
                    ;;
                ' ' | '') # Enter or Space entered, return the default value if supplied
                    if [[ -n ${Default-} ]]; then
                        YN="${Default}"
                        break
                    fi
                    ;;
                *) ;;
            esac
        done
        if [[ ${YN} == "Y" ]]; then
            notice "Answered: ${C["Yes"]}Yes${NC}"
        else
            notice "Answered: ${C["No"]}No${NC}"
        fi
    else
        YN=${Default:-Y}
    fi
    [ "${YN}" == "Y" ]
}

test_question_prompt() {
    run_script 'question_prompt'
}
