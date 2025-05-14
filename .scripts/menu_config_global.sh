#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_config_global() {
    local Title="Edit Global Variables"

    local ColorHeading='\Zr'
    #local ColorHeadingLine='\Zn'
    local ColorCommentLine='\Z0\Zb\Zr'
    local ColorOtherLine="${ColorCommentLine}"
    local ColorVarLine='\Z0\ZB\Zr'
    local ColorAddVariableLine='\Z0\ZB\Zr'
    local AddVariableText='<ADD VARIABLE>'
    local -a DefaultGlobalVarList=()
    # Get the list of global variables for the app
    readarray -t DefaultGlobalVarList < <(run_script 'env_var_list' "${COMPOSE_ENV_DEFAULT_FILE}")
    local DefaultGlobalVarListRegex
    {
        IFS='|'
        DefaultGlobalVarListRegex="${DefaultGlobalVarList[*]}"
    }

    local CurrentGlobalEnvFile
    CurrentGlobalEnvFile=$(mktemp)
    run_script 'appvars_lines' "" > "${CurrentGlobalEnvFile}"

    local LastLineChoice=""
    while true; do
        local -a LineOptions=()
        local -a VarNameOnLine=()
        local -a CurrentValueOnLine=()
        local -a LineColor=()
        local -i LineNumber=0
        local FirstVarLine
        run_script 'appvars_lines' "" > "${CurrentGlobalEnvFile}"
        local -a CurrentGlobalEnvLines
        readarray -t CurrentGlobalEnvLines < <(
            run_script 'env_format_lines' "${CurrentGlobalEnvFile}" "${COMPOSE_ENV_DEFAULT_FILE}"
        )
        for line in "${CurrentGlobalEnvLines[@]}"; do
            ((++LineNumber))
            CurrentValueOnLine[LineNumber]="${line}"
            local VarName
            VarName="$(grep -o -P '^\w+(?=)' <<< "${line}")"
            if [[ -n ${VarName-} ]]; then
                # Line contains a variable
                LineColor[LineNumber]="${ColorVarLine}"
                VarNameOnLine[LineNumber]="${VarName}"
                if [[ -z ${FirstVarLine-} ]]; then
                    FirstVarLine=${LineNumber}
                fi
            elif (grep -q -P '^\s*#' <<< "${line}"); then
                # Line is a comment
                LineColor[LineNumber]="${ColorCommentLine}"
            else
                # Line is an unknowwn line
                LineColor[LineNumber]="${ColorOtherLine}"
            fi
        done
        ((LineNumber++))
        local AddVariableLineNumber=${LineNumber}
        CurrentValueOnLine[LineNumber]="${AddVariableText}"
        LineColor[LineNumber]="${ColorAddVariableLine}"
        local TotalLines=$((10#${LineNumber}))
        local PadSize=${#TotalLines}
        for LineNumber in "${!CurrentValueOnLine[@]}"; do
            local PaddedLineNumber=""
            PaddedLineNumber="$(printf "%0${PadSize}d" "${LineNumber}")"
            LineOptions+=("${PaddedLineNumber}" "${LineColor[LineNumber]-}${CurrentValueOnLine[LineNumber]}")
        done
        if [[ -z ${LastLineChoice-} ]]; then
            # Set the default line to the first line with a variable on it
            LastLineChoice="$(printf "%0${PadSize}d" "${FirstVarLine}")"
        fi
        local -a LineDialog=(
            --stdout
            --colors
            --ok-label "Select"
            --cancel-label "Done"
            --title "${Title}"
            --menu "\nFile: ${ColorHeading}${COMPOSE_ENV}\Zn\n" 0 0 0
            "${LineOptions[@]}"
        )
        while true; do
            local -i LineDialogButtonPressed=0
            LineChoice=$(dialog --default-item "${LastLineChoice}" "${LineDialog[@]}") || LineDialogButtonPressed=$?
            case ${DIALOG_BUTTONS[LineDialogButtonPressed]-} in
                OK)
                    LastLineChoice="${LineChoice}"
                    local LineNumber
                    LineNumber=$((10#${LineChoice}))
                    if [[ ${LineNumber} == "${AddVariableLineNumber}" ]]; then
                        run_script 'menu_add_var'
                    elif [[ -n ${VarNameOnLine[LineNumber]-} ]]; then
                        local VarIsUserDefined='Y'
                        if [[ ${VarNameOnLine[LineNumber]-} =~ ${DefaultGlobalVarListRegex} ]]; then
                            VarIsUserDefined=''
                        fi
                        run_script 'menu_value_prompt' "${VarNameOnLine[LineNumber]}" "${VarIsUserDefined}"
                        break
                    fi
                    ;;
                CANCEL | ESC)
                    return
                    ;;
                *)
                    if [[ -n ${DIALOG_BUTTONS[LineDialogButtonPressed]-} ]]; then
                        clear
                        fatal "Unexpected dialog button '${DIALOG_BUTTONS[LineDialogButtonPressed]}' pressed."
                    else
                        clear
                        fatal "Unexpected dialog button value '${LineDialogButtonPressed}' pressed."
                    fi
                    ;;
            esac
        done
    done
    rm -f "${CurrentGlobalEnvFile}" ||
        warn "Failed to remove temporary .env file.\nFailing command: ${F[C]}rm -f \"${CurrentGlobalEnvFile}\""

}

test_menu_config_global() {
    # run_script 'menu_config_global'
    warn "CI does not test menu_config_global."
}
