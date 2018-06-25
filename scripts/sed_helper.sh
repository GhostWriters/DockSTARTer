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
        fatal "ReplaceString Param1 not set"
    elif [[ -z ${REPLACESTR} ]]; then
        fatal "ReplaceString Param2 not set"
    elif [[ -z ${FILE} ]]; then
        fatal "ReplaceString Param3 not set"
    fi

    #Check Param3 (FILE) to change exists
    if [[ ! -f ${FILE} ]]; then
        fatal "ReplaceString ${FILE} not found"
    fi

    #Check Param1 exists in the file.
    if ! grep -q "${FINDSTR}" "${FILE}"; then
        if [[ ${IGNORE} != 'IgnoreError' ]]; then
            fatal "ReplaceString ${FINDSTR} not found in ${FILE}"
        fi
    else
        #Perform the Replace
        sed -i "s|${FINDSTR}|${REPLACESTR}|" "${FILE}" || fatal "ReplaceString Replacing Param1 with Param2 in Param3 failed."

        #Check Param2 exists in the file after the change
        if grep -q "${REPLACESTR}" "${FILE}" || fatal "ReplaceString Param2 not found in Param3"; then
            info "Replaced ${YELLOW}${FINDSTR}${ENDCOLOR} with ${GREEN}${REPLACESTR}${ENDCOLOR} in ${YELLOW}${FILE}${ENDCOLOR}"
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
        fatal "SetVariableValue Param1 not set"
    elif [[ -z ${REPLACESTR} ]]; then
        fatal "SetVariableValue Param2 not set"
    elif [[ -z ${FILE} ]]; then
        fatal "SetVariableValue Param3 not set"
    fi

    #Check Param3 (FILE) to change exists
    if [[ ! -f ${FILE} ]]; then
        fatal "SetVariableValue ${FILE} not found"
    fi

    #Check Param1 exists in the file.
    if ! grep -q "${FINDSTR}" "${FILE}"; then
        if [[ ${IGNORE} != 'IgnoreError' ]]; then
            fatal "SetVariableValue ${FINDSTR} not found in ${FILE}"

        fi
    else
        #Perform the Replace
        sed -i "s|${FINDSTR}=.*|${FINDSTR}=${REPLACESTR}|" "${FILE}" || fatal "SetVariableValue Replacing Param1 with Param2 in Param3 failed."

        #Check Param2 exists in the file after the change
        if grep -q "${REPLACESTR}" "${FILE}" || fatal "SetVariableValue Param2 not found in Param3"; then
            info "Set ${YELLOW}${FINDSTR}${ENDCOLOR}=${GREEN}${REPLACESTR}${ENDCOLOR} in ${YELLOW}${FILE}${ENDCOLOR}"
        fi
    fi
}
