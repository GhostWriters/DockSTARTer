#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

ReplaceString() {
    local FINDSTR
    FINDSTR=${1}
    local REPLACESTR
    REPLACESTR=${2}
    local FILE
    FILE=${3}
    local IGNORE
    IGNORE=${4}
    #Check all 3 params at set
    if [[ -z ${FINDSTR} ]]; then
        echo -e "${RED}ReplaceString Param1 not set${ENDCOLOR}"; exit 1
    elif [[ -z ${REPLACESTR} ]]; then
        echo -e "${RED}ReplaceString Param2 not set${ENDCOLOR}"; exit 1
    elif [[ -z ${FILE} ]]; then
        echo -e "${RED}ReplaceString Param3 not set${ENDCOLOR}"; exit 1
    fi

    #Check Param3 (FILE) to change exists
    if [[ ! -f ${FILE} ]]; then
        echo -e "${RED}ReplaceString ${FILE} not found${ENDCOLOR}"; exit 1
    fi

    #Check Param1 exists in the file.
    if ! grep -q "${FINDSTR}" "${FILE}"; then
        if [[ ${IGNORE} != 'IgnoreError' ]]; then
            echo -e "${RED}ReplaceString ${FINDSTR} not found in ${FILE}${ENDCOLOR}"; exit 1
        fi
    else
        #Perform the Replace
        sed -i "s|${FINDSTR}|${REPLACESTR}|" "${FILE}" || { echo -e "${RED}ReplaceString Replacing Param1 with Param2 in Param3 failed.${ENDCOLOR}"; exit 1; }

        #Check Param2 exists in the file after the change
        if grep -q "${REPLACESTR}" "${FILE}" || \
            { echo -e "${RED}ReplaceString Param2 not found in Param3${ENDCOLOR}"; exit 1; }; then
            echo -e "Replaced ${CYAN}${FINDSTR}${ENDCOLOR} with ${CYAN}${REPLACESTR}${ENDCOLOR} in ${CYAN}${FILE}${ENDCOLOR}"
        fi
    fi
}

SetVariableValue() {
    local FINDSTR
    FINDSTR="${1}"
    local REPLACESTR
    REPLACESTR="${2}"
    local FILE
    FILE="${3}"
    local IGNORE
    IGNORE="${4}"
    #Check all 3 params at set
    if [[ -z ${FINDSTR} ]]; then
        echo -e "${RED}SetVariableValue Param1 not set${ENDCOLOR}"; exit 1
    elif [[ -z ${REPLACESTR} ]]; then
        echo -e "${RED}SetVariableValue Param2 not set${ENDCOLOR}"; exit 1
    elif [[ -z ${FILE} ]]; then
        echo -e "${RED}SetVariableValue Param3 not set${ENDCOLOR}"; exit 1
    fi

    #Check Param3 (FILE) to change exists
    if [[ ! -f ${FILE} ]]; then
        echo -e "${RED}SetVariableValue ${FILE} not found${ENDCOLOR}"; exit 1
    fi

    #Check Param1 exists in the file.
    if ! grep -q "${FINDSTR}" "${FILE}"; then
        if [[ ${IGNORE} != 'IgnoreError' ]]; then
            echo -e "${RED}SetVariableValue ${FINDSTR} not found in ${FILE}${ENDCOLOR}"; exit 1
        fi
    else
        #Perform the Replace
        sed -i "s|${FINDSTR}=.*|${FINDSTR}=${REPLACESTR}|" "${FILE}" || { echo -e "${RED}SetVariableValue Replacing Param1 with Param2 in Param3 failed.${ENDCOLOR}"; exit 1; }

        #Check Param2 exists in the file after the change
        if grep -q "${REPLACESTR}" "${FILE}" || \
            { echo -e "${RED}SetVariableValue Param2 not found in Param3${ENDCOLOR}"; exit 1; }; then
            echo -e "Set ${CYAN}${FINDSTR}${ENDCOLOR}=${GREEN}${REPLACESTR}${ENDCOLOR} in ${CYAN}${FILE}${ENDCOLOR}"
        fi
    fi
}
