#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_app_vars() {
    local APPNAME=${1-}
    APPNAME=${APPNAME^^}
    local appname=${APPNAME,,}
    local AppName
    AppName=$(run_script 'app_nicename' "${APPNAME}")
    local Title="Set App Variables"

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
    local ColorVarLine='\Z0\Zb\Zr'
    #local ColorCommentLine='\Z0\ZB\Zr'
    local ColorHeadingLine='\Zn'

    run_script_dialog "${Title}" "Creating variables for ${AppName}" 1 \
        'appvars_create' "${APPNAME}"

    local -a AppVarGlobalList
    local -a AppVarEnvList
    readarray -t AppVarGlobalList < <(run_script 'env_list_app_global_defaults' "${AppName}")
    readarray -t AppVarEnvList < <(run_script 'env_list_app_env_defaults' "${AppName}")
    if [[ -z ${AppVarGlobalList[*]} && -z ${AppVarEnvList[*]} ]]; then
        local Message="Application '${AppName} has no variables."
        if [[ ${CI-} == true ]]; then
            warn "${Message}"
        else
            dialog --title "${Title}" --msgbox "${Message}" 0 0
        fi
        return
    fi

    local -a AppVarList=("${AppVarGlobalList[@]}")
    for VarName in "${AppVarEnvList[@]}"; do
        AppVarList+=("${appname}:${VarName}")
    done

    local LastLineChoice=""
    while true; do
        local -a LineOptions=()
        local -a VarNameOnLine=()
        local -a CurrentValueOnLine=()
        local -a LineColor=()
        #local -a DefaultValueOnLine=()
        local LineNumber=0
        local FirstVarLine
        if [[ -n ${AppVarGlobalList[*]} ]]; then
            ((++LineNumber))
            CurrentValueOnLine[LineNumber]="*** ${COMPOSE_ENV} ***"
            #DefaultValueOnLine[LineNumber]="*** ${COMPOSE_ENV} ***"
            LineColor[LineNumber]="${ColorHeadingLine}"
            if [[ -z ${FirstVarLine-} ]]; then
                FirstVarLine=$((LineNumber + 1))
            fi
            for VarName in "${AppVarGlobalList[@]}"; do
                ((++LineNumber))
                VarNameOnLine[LineNumber]="${VarName}"
                CurrentValueOnLine[LineNumber]="${VarName}=$(run_script 'env_get_literal' "${VarName}")"
                #DefaultValueOnLine[LineNumber]="${VarName}=$(run_script 'env_get_literal' "${VarName}")"
                LineColor[LineNumber]="${ColorVarLine}"
            done
        fi
        if [[ -n ${AppVarEnvList[*]-} ]]; then
            if [[ ${LineNumber} != 0 ]]; then
                ((++LineNumber))
                CurrentValueOnLine[LineNumber]=""
                #DefaultValueOnLine[LineNumber]=""
                LineColor[LineNumber]="${ColorVarLine}"
            fi
            ((++LineNumber))
            CurrentValueOnLine[LineNumber]="*** ${APP_ENV_FOLDER_NAME}/${appname}.env ***"
            #DefaultValueOnLine[LineNumber]="*** ${APP_ENV_FOLDER_NAME}/${appname}.env ***"
            LineColor[LineNumber]="${ColorHeadingLine}"
            if [[ -z ${FirstVarLine-} ]]; then
                FirstVarLine=$((LineNumber + 1))
            fi
            for VarName in "${AppVarEnvList[@]}"; do
                ((++LineNumber))
                VarNameOnLine[LineNumber]="${appname}:${VarName}"
                CurrentValueOnLine[LineNumber]="${VarName}=$(run_script 'env_get_literal' "${appname}:${VarName}")"
                #DefaultValueOnLine[LineNumber]="${VarName}=$(run_script 'env_get_literal' "${appname}:${VarName}"")"
                LineColor[LineNumber]="${ColorVarLine}"
            done
        fi
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
            --title "${Title}"
            --cancel-button "Back"
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
                    if [[ -n ${VarNameOnLine[LineNumber]-} ]]; then
                        run_script 'menu_value_prompt' "${VarNameOnLine[LineNumber]}"
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
}

test_menu_app_vars() {
    # run_script 'menu_app_vars'
    warn "CI does not test menu_app_vars."
}
