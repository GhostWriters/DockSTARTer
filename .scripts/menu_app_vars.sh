#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_app_vars() {
    local APPNAME=${1-}
    APPNAME=${APPNAME^^}
    local appname=${APPNAME,,}
    local AppName
    AppName=$(run_script 'app_nicename' "${APPNAME}")
    local Title="Edit Application Variables"

    if ! run_script 'app_is_builtin'; then
        local Message="Application '${AppName}' does not exist."
        if [[ ${CI-} == true ]]; then
            warn "${Message}"
        else
            dialog --title "${Title}" --msgbox "${Message}" 0 0
        fi
        return
    fi

    local ColorHeading='\Zr'
    local ColorHeadingLine='\Zn'
    local ColorCommentLine='\Z0\Zb\Zr'
    local ColorOtherLine="${ColorCommentLine}"
    local ColorVarLine='\Z0\ZB\Zr'
    local ColorAddVariableLine='\Z0\ZB\Zr'
    local AddVariableText='<ADD VARIABLE>'

    run_script_dialog "${Title}" "Creating variables for ${AppName}" 1 \
        'appvars_create' "${APPNAME}"

    local -a DefaultVarList=()
    local -a DefaultAppEnvVarList=()
    # Get the list of global variables for the app
    readarray -t DefaultVarList < <(run_script 'env_list_app_global_defaults' "${AppName}")
    # Add the list of app-specific variables for the app
    readarray -t DefaultAppEnvVarList < <(run_script 'env_list_app_env_defaults' "${AppName}")
    for VarName in "${DefaultAppEnvVarList[@]}"; do
        DefaultVarList+=("${appname}:${VarName}")
    done
    local DefaultVarListRegex
    {
        IFS='|'
        DefaultVarListRegex="${DefaultVarList[*]}"
    }
    local DefaultGlobalEnvFile="${TEMPLATES_FOLDER}/${appname}/.env"
    local CurrentGlobalEnvFile
    CurrentGlobalEnvFile=$(mktemp)

    local DefaultAppEnvFile="${TEMPLATES_FOLDER}/${appname}/${appname}.env"
    local CurrentAppEnvFile
    CurrentAppEnvFile=$(mktemp)

    local LastLineChoice=""
    while true; do
        local -a LineOptions=()
        local -a VarNameOnLine=()
        local -a CurrentValueOnLine=()
        local -a LineColor=()
        local -i LineNumber=0
        local FirstVarLine
        ((++LineNumber))
        LineColor[LineNumber]="${ColorHeadingLine}"
        CurrentValueOnLine[LineNumber]="*** ${COMPOSE_ENV} ***"
        run_script 'appvars_lines' "${appname}" > "${CurrentGlobalEnvFile}"
        local -a CurrentGlobalEnvLines
        readarray -t CurrentGlobalEnvLines < <(
            run_script 'env_format_lines' "${CurrentGlobalEnvFile}" "${DefaultGlobalEnvFile}" "${appname}"
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
        local AddGlobalVariableLineNumber=${LineNumber}
        CurrentValueOnLine[LineNumber]="${AddVariableText}"
        LineColor[LineNumber]="${ColorAddVariableLine}"
        ((++LineNumber))
        CurrentValueOnLine[LineNumber]=""
        LineColor[LineNumber]="${ColorOtherLine}"

        ((++LineNumber))
        CurrentValueOnLine[LineNumber]="*** ${APP_ENV_FOLDER}/${appname}.env ***"
        LineColor[LineNumber]="${ColorHeadingLine}"
        run_script 'appvars_lines' "${appname}:" > "${CurrentAppEnvFile}"
        local -a CurrentAppEnvLines
        readarray -t CurrentAppEnvLines < <(
            run_script 'env_format_lines' "${CurrentAppEnvFile}" "${DefaultAppEnvFile}" "${appname}"
        )
        for line in "${CurrentAppEnvLines[@]}"; do
            ((++LineNumber))
            CurrentValueOnLine[LineNumber]="${line}"
            local VarName
            VarName="$(grep -o -P '^\w+(?=)' <<< "${line}")"
            if [[ -n ${VarName-} ]]; then
                # Line contains a variable
                LineColor[LineNumber]="${ColorVarLine}"
                VarNameOnLine[LineNumber]="${appname}:${VarName}"
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
        local AddAppEnvVariableLineNumber=${LineNumber}
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
            --menu "\nApplication: ${ColorHeading}${AppName}\Zn\n" 0 0 0
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
                    if [[ ${LineNumber} == "${AddGlobalVariableLineNumber}" ]]; then
                        run_script 'menu_add_var' "${appname}"
                    elif [[ ${LineNumber} == "${AddAppEnvVariableLineNumber}" ]]; then
                        run_script 'menu_add_var' "${appname}:"
                    elif [[ -n ${VarNameOnLine[LineNumber]-} ]]; then
                        local VarIsUserDefined='Y'
                        if [[ ${VarNameOnLine[LineNumber]-} =~ ${DefaultVarListRegex} ]]; then
                            VarIsUserDefined=''
                        fi
                        run_script 'menu_value_prompt' "${VarNameOnLine[LineNumber]}" "${VarIsUserDefined}"
                        break
                    fi
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
    rm -f "${CurrentAppEnvFile}" ||
        warn "Failed to remove temporary ${appname}.env file.\nFailing command: ${F[C]}rm -f \"${CurrentAppEnvFile}\""

}

test_menu_app_vars() {
    # run_script 'menu_app_vars'
    warn "CI does not test menu_app_vars."
}
