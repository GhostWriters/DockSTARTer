#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

input_prompt() {
    if [[ ${CI:-} != true ]] && [[ ${TRAVIS:-} != true ]]; then
        INPUT=$(whiptail --inputbox "What would you like to set ${1} to?" 12 78 "${2}" --fb --title "Set folder" 3>&1 1>&2 2>&3)
    else
        INPUT="${2}"
    fi
    
    if [[ -d ${INPUT} ]]; then
        SetVariableValue "${1}" "${INPUT}" "${SCRIPTPATH}/compose/.env"
    else
        whiptail --title "Error" --msgbox "${INPUT} is not a valid path. Please try again." --fb 9 78
        input_prompt "${1}" "${2}"
    fi
}
