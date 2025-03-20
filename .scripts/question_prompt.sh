#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

question_prompt() {
    local PROMPT=${1-}
    local DEFAULT=${2:-Y}
    local QUESTION=${3-}
    local Title=${4-$BACKTITLE}
    local YN
    while true; do
        if [[ ${CI-} == true ]]; then
            YN=${DEFAULT}
        elif [[ ${PROMPT-} == "CLI" ]]; then
            notice "${QUESTION}"
            read -rp "[Yn]" YN < /dev/tty
        elif [[ ${PROMPT-} == "GUI" ]]; then
            local DIALOG_DEFAULT
            if [[ ${DEFAULT} == "N" ]]; then
                DIALOG_DEFAULT="--defaultno"
            fi
            # shellcheck disable=SC2206 # (warning): Quote to prevent word splitting/globbing, or split robustly with mapfile or read -a.
            local -a YesNoDialog=(
                --fb
                --clear
                --title "${Title}"
                ${DIALOG_DEFAULT-}
                --yesno "${QUESTION}"
                0 0
            )
            set +e
            YN=$(dialog "${YesNoDialog[@]}" 3>&1 1>&2 2>&3 && echo "Y" || echo "N")
            set -e
        elif [[ ${PROMPT-} == "FORCE" ]]; then
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
