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
    local Title=${3-$BACKTITLE}
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
        # shellcheck disable=SC2206 # (warning): Quote to prevent word splitting/globbing, or split robustly with mapfile or read -a.
        local -a YesNoDialog=(
            --stdout
            --begin "${DC[OffsetTop]}" "${DC[OffsetLeft]}"
            --no-collapse
            --yes-label "${YesButton}"
            --no-label "${NoButton}"
            --title "${DC["Title"]}${Title}"
            ${DIALOG_DEFAULT-}
            --yesno "${Question}"
            "$((LINES - DC["WindowHeightAdjust"]))" "$((COLUMNS - DC["WindowWidthAdjust"]))"
        )
        while true; do
            local YNPrompt
            if [[ ${Default} == Y ]]; then
                YNPrompt='[Yn]'
            elif [[ ${Default} == N ]]; then
                YNPrompt='[yN]'
            else
                YNPrompt='[YN]'
            fi
            notice "${Question}" &> /dev/null
            notice "${YNPrompt}" &> /dev/null
            local -i YesNoDialogButtonPressed=0
            dialog "${YesNoDialog[@]}" || YesNoDialogButtonPressed=$?
            case ${DIALOG_BUTTONS[YesNoDialogButtonPressed]-} in
                OK)
                    YN="Y"
                    notice "Answered: ${YN}" &> /dev/null
                    break
                    ;;
                CANCEL | ESC)
                    YN="N"
                    notice "Answered: ${YN}" &> /dev/null
                    break
                    ;;
                *)
                    if [[ -n ${DIALOG_BUTTONS[YesNoDialogButtonPressed]-} ]]; then
                        clear
                        fatal "Unexpected dialog button '${DIALOG_BUTTONS[YesNoDialogButtonPressed]}' pressed."
                    else
                        clear
                        fatal "Unexpected dialog button value '${YesNoDialogButtonPressed}' pressed."
                    fi
                    ;;
            esac
        done
    elif [[ ${PROMPT:-CLI} == "CLI" ]]; then
        local YNPrompt
        if [[ ${Default} == Y ]]; then
            YNPrompt='[Yn]'
        elif [[ ${Default} == N ]]; then
            YNPrompt='[yN]'
        else
            YNPrompt='[YN]'
        fi
        notice "${Question}"
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
        notice "Answered: ${YN}"
    else
        YN=${Default:-Y}
    fi
    [ "${YN}" == "Y" ]
}

test_question_prompt() {
    run_script 'question_prompt'
}
