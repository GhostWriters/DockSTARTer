#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

question_prompt() {
    local DEFAULT=${1:-Y}
    local QUESTION=${2-}
    local Title=${3-$BACKTITLE}
    local YN
    while true; do
        if [[ ${CI-} == true ]]; then
            YN=${DEFAULT}
        elif [[ ${PROMPT:-CLI} == "CLI" ]]; then
            notice "${QUESTION}"
            read -rp "[Yn]" YN < /dev/tty
        elif [[ ${PROMPT:-CLI} == "GUI" ]]; then
            local DIALOG_DEFAULT
            if [[ ${DEFAULT} == "N" ]]; then
                DIALOG_DEFAULT="--defaultno"
            fi
            # shellcheck disable=SC2206 # (warning): Quote to prevent word splitting/globbing, or split robustly with mapfile or read -a.
            local -a YesNoDialog=(
                --stdout
                --title "${Title}"
                ${DIALOG_DEFAULT-}
                --yesno "${QUESTION}"
                0 0
            )
            local DIALOG_BUTTON_PRESSED
            DIALOG_BUTTON_PRESSED=0 && dialog "${YesNoDialog[@]}" || DIALOG_BUTTON_PRESSED=$?
            case ${DIALOG_BUTTON_PRESSED} in
                "${DIALOG_OK}")
                    YN="Y"
                    ;;
                "${DIALOG_CANCEL}" | "${DIALOG_ESC}")
                    YN="N"
                    ;;
                *)
                    if [[ -n ${DIALOG_BUTTONS[$DIALOG_BUTTON_PRESSED]-} ]]; then
                        clear
                        fatal "Unexpected dialog button '${DIALOG_BUTTONS[$DIALOG_BUTTON_PRESSED]}' pressed."
                    else
                        clear
                        fatal "Unexpected dialog button value'${DIALOG_BUTTON_PRESSED}' pressed."
                    fi
                    ;;
            esac
        elif [[ ${FORCE-} == true ]]; then
            YN=${DEFAULT}
        else
            YN=${DEFAULT}
        fi
        case ${YN} in
            [Yy]*)
                return
                ;;
            [Nn]*)
                return 1
                ;;
            *)
                error "Please answer yes or no."
                ;;
        esac
    done
}

test_question_prompt() {
    run_script 'question_prompt'
}
