#!/bin/bash

ReplaceString()
{
    #Check all 3 params at set
    if [[ -z $1 ]]; then
        echo -e "${RED}ReplaceString Param1 not set$ENDCOLOR"; exit 1
    elif [[ -z $2 ]]; then
        echo -e "${RED}ReplaceString Param2 not set$ENDCOLOR"; exit 1
    elif [[ -z $3 ]]; then
        echo -e "${RED}ReplaceString Param3 not set$ENDCOLOR"; exit 1
    fi

    #Check Param3 (FILE) to change exists
    if [[ ! -f $3 ]]; then
        echo -e "${RED}ReplaceString $3 not found$ENDCOLOR"; exit 1
    fi

    #Check Param1 exists in the file.
    if ! grep -q "$1" "$3"; then
        if [[ $4 != 'IgnoreError' ]]; then
            echo -e "${RED}ReplaceString $1 not found in $3$ENDCOLOR"; exit 1
        fi
    else
        #Perform the Replace
        sed -i "s|$1|$2|" "$3" || { echo -e "${RED}ReplaceString Replacing Param1 with Param2 in Param3 failed.$ENDCOLOR"; exit 1; }

        #Check Param2 exists in the file after the change
        if grep -q "$2" "$3" || \
                { echo -e "${RED}ReplaceString Param2 not found in Param3$ENDCOLOR"; exit 1; }; then
            echo -e "Replaced ${CYAN}$1$ENDCOLOR with ${CYAN}$2$ENDCOLOR in ${CYAN}$3$ENDCOLOR"
        fi
    fi
}

SetVariableValue()
{
    #Check all 3 params at set
    if [[ -z $1 ]]; then
        echo -e "${RED}SetVariableValue Param1 not set$ENDCOLOR"; exit 1
    elif [[ -z $2 ]]; then
        echo -e "${RED}SetVariableValue Param2 not set$ENDCOLOR"; exit 1
    elif [[ -z $3 ]]; then
        echo -e "${RED}SetVariableValue Param3 not set$ENDCOLOR"; exit 1
    fi

    #Check Param3 (FILE) to change exists
    if [[ ! -f $3 ]]; then
        echo -e "${RED}SetVariableValue $3 not found$ENDCOLOR"; exit 1
    fi

    #Check Param1 exists in the file.
    if ! grep -q "$1" "$3"; then
        if [[ $4 != 'IgnoreError' ]]; then
            echo -e "${RED}SetVariableValue $1 not found in $3$ENDCOLOR"; exit 1
        fi
    else
        #Perform the Replace
        sed -i "s|$1=.*|$1=$2|" "$3" || { echo -e "${RED}SetVariableValue Replacing Param1 with Param2 in Param3 failed.$ENDCOLOR"; exit 1; }

        #Check Param2 exists in the file after the change
        if grep -q "$2" "$3" || \
                { echo -e "${RED}SetVariableValue Param2 not found in Param3$ENDCOLOR"; exit 1; }; then
            echo -e "Set ${CYAN}$1$ENDCOLOR=${GREEN}$2$ENDCOLOR in ${CYAN}$3$ENDCOLOR"
        fi
    fi
}
