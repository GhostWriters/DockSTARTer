#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

question_prompt() {
    local PROMPT=${1:-}
    local DEFAULT=${2:-Y}
    local QUESTION=${3:-}
    local YN
    while true; do
        if [[ ${CI:-} == true ]]; then
            YN=${DEFAULT}
        elif [[ ${PROMPT:-} == "CLI" ]]; then
            notice "${QUESTION}"
            read -rp "[Yn]" YN < /dev/tty
        elif [[ ${PROMPT:-} == "GUI" ]]; then
            local WHIPTAIL_DEFAULT
            if [[ ${DEFAULT} == "N" ]]; then
                WHIPTAIL_DEFAULT=" --defaultno "
            fi
            local ANSWER
            set +e
            ANSWER=$(
                eval whiptail --fb --clear --title "DockSTARTer" "${WHIPTAIL_DEFAULT:-}" --yesno \""${QUESTION}"\" 0 0 3>&1 1>&2 2>&3
                echo $?
            )
            set -e
            if [[ ${ANSWER} == 0 ]]; then
                YN=Y
            else
                YN=N
            fi
        elif [[ ${PROMPT:-} == "FORCE" ]]; then
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
