#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

input_prompt() {
    local SET_VAR
    SET_VAR=${1:-}
    local NEW_VAL
    NEW_VAL=${2:-}
    local INPUT
    if [[ ${CI:-} != true ]] && [[ ${TRAVIS:-} != true ]]; then
        INPUT=$(whiptail --inputbox "What would you like to set ${SET_VAR} to?" 12 78 "${NEW_VAL}" --fb --title "Set folder" 3>&1 1>&2 2>&3)
    else
        INPUT="${2}"
    fi

    if [[ -d ${INPUT} ]]; then
        run_script 'env_set' "${SET_VAR}" "${INPUT}"
    else
        whiptail --title "Error" --msgbox "${INPUT} is not a valid path. Please try again." --fb 9 78
        input_prompt "${SET_VAR}" "${NEW_VAL}"
    fi
}
