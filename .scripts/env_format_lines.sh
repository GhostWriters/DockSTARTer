#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

env_format_lines() {
    local CurrentEnvFile=${1-}
    local DefaultEnvFile=${2-}
    local APPNAME=${3-}
    APPNAME=${APPNAME^^}

    local GlobalVarsHeading="Global Variables"
    local AppDepreciatedTag=" [*DEPRECIATED*]"
    local AppDisabledTag=" (Disabled)"
    local AppUserDefinedTag=" (User Defined)"
    local UserDefinedVarsTag=" (User Defined Variables)"
    local UserDefinedGlobalVarsTag=" (User Defined)"

    local -a CurrentEnvLines=()
    readarray -t CurrentEnvLines < <(
        run_script 'env_lines' "${CurrentEnvFile}"
    )

    local AppName=''
    local AppDescription=''
    local AppIsUserDefined=''
    local -a FormattedEnvLines=()
    if [[ -n ${APPNAME-} ]]; then
        # APPNAME is specified and added, output main app heading
        if run_script 'app_is_user_defined' "${APPNAME}"; then
            AppIsUserDefined='Y'
        fi
        AppName="$(run_script 'app_nicename' "${APPNAME}")"
        AppDescription="$(run_script 'app_description' "${APPNAME}" | fold -s -w 75)"
        local HeadingTitle="${AppName}"
        if [[ ${AppIsUserDefined} == Y ]]; then
            HeadingTitle+="${AppUserDefinedTag}"
        else
            run_script 'app_is_depreciated' "${APPNAME}" && HeadingTitle+="${AppDepreciatedTag}"
            run_script 'app_is_disabled' "${APPNAME}" && HeadingTitle+="${AppDisabledTag}"
        fi

        local -a HeadingText=()
        HeadingText+=("")
        readarray -t -O ${#HeadingText[@]} HeadingText < <(printf '%b\n' "${HeadingTitle}")
        HeadingText+=("")
        readarray -t -O ${#HeadingText[@]} HeadingText < <(printf '%b\n' "${AppDescription}")
        HeadingText+=("")

        readarray -t -O ${#FormattedEnvLines[@]} FormattedEnvLines < <(
            printf '### %b\n' "${HeadingText[@]}"
        )
    fi
    if [[ -n ${DefaultEnvFile} && -f ${DefaultEnvFile} ]]; then
        # Default file is specified and exists, add the contents verbatim
        readarray -t -O ${#FormattedEnvLines[@]} FormattedEnvLines < "${DefaultEnvFile}"
        if [[ -n ${FormattedEnvLines[*]} ]]; then
            # Add a blank if there are existing lines (not at top of file)
            FormattedEnvLines+=("")
        fi
    fi

    # FormattedEnvVarIndex["VarName"]=index position of line in FormattedEnvLines
    local -A FormattedEnvVarIndex=()
    local -a VarLines=()
    # Make an array with the contents "line number:VARIABLE" in each element
    readarray -t VarLines < <(
        printf '%s\n' "${FormattedEnvLines[@]}" | grep -n -o -P '^[A-Za-z0-9_]*(?=[=])' || true
    )
    for line in "${VarLines[@]}"; do
        local index=${line%:*}
        index=$((index - 1))
        local VarName=${line#*:}
        FormattedEnvVarIndex[$VarName]=$index
    done

    if [[ -n ${CurrentEnvLines[*]} ]]; then
        # Update the default variables
        for index in "${!CurrentEnvLines[@]}"; do
            local line=${CurrentEnvLines[index]}
            local VarName=${line%%=*}
            if [[ -n ${FormattedEnvVarIndex[$VarName]-} ]]; then
                # Variable already exists, update its value
                FormattedEnvLines[${FormattedEnvVarIndex[$VarName]}]=$line
                unset 'CurrentEnvLines[index]'
            fi
        done
        CurrentEnvLines=("${CurrentEnvLines[@]-}")
        if [[ -n ${CurrentEnvLines[*]} ]]; then
            if [[ -z ${APPNAME-} || ${AppIsUserDefined} != Y ]]; then
                # Add the "User Defined" heading
                local HeadingTitle
                if [[ -n ${AppName-} ]]; then
                    HeadingTitle="${AppName}${UserDefinedVarsTag}"
                else
                    HeadingTitle="${GlobalVarsHeading}${UserDefinedGlobalVarsTag}"
                fi
                local HeadingText=()
                HeadingText+=("")
                readarray -t -O ${#HeadingText[@]} HeadingText < <(printf '%b\n' "${HeadingTitle}")
                HeadingText+=("")
                readarray -t -O ${#FormattedEnvLines[@]} FormattedEnvLines < <(
                    printf '### %b\n' "${HeadingText[@]}"
                )
            fi
            # Add the user defined variables
            for index in "${!CurrentEnvLines[@]}"; do
                local line=${CurrentEnvLines[index]}
                local VarName=${line%%=*}
                if [[ -n ${FormattedEnvVarIndex[$VarName]-} ]]; then
                    # Variable already exists, update its value
                    FormattedEnvLines[${FormattedEnvVarIndex[$VarName]}]=$line
                else
                    # Variable is new, add it
                    FormattedEnvLines+=("$line")
                    FormattedEnvVarIndex[$VarName]=$((${#FormattedEnvLines[@]} - 1))
                fi
            done
            FormattedEnvLines+=("")
        fi
    else
        FormattedEnvLines+=("")
    fi
    printf "%s\n" "${FormattedEnvLines[@]-}"
}

test_env_format_lines() {
    #run_script 'env_format_lines' WATCHTOWER
    warn "CI does not test env_format_lines."
}
