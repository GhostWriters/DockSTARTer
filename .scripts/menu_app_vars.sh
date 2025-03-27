#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_app_vars() {
    local APPNAME=${1-}
    APPNAME=${APPNAME^^}
    local appname=${APPNAME,,}
    local AppName
    AppName=$(run_script 'app_nicename' "${APPNAME}")
    local Title="Application Variables - ${AppName}"

    if ! run_script 'app_is_builtin'; then
        local Message="Application '${AppName}' does not exist."
        if [[ ${CI-} == true ]]; then
            warn "${Message}"
        else
            dialog --title "${Title}" --msgbox "${Message}" 0 0
        fi
        return
    fi

    run_script 'appvars_create' "${APPNAME}" |& dialog --timeout 1 --title "${BACKTITLE}" --programbox "${Title}" -1 -1

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

    local LineButtonPressed=""
    while true; do
        local -a LineOptions=()
        local -a VarNameOnLine=()
        local -a CurrentValueOnLine=()
        local -a LineColor=()
        #local -a DefaultValueOnLine=()
        local LineNumber=0
        if [[ -n ${AppVarGlobalList[*]} ]]; then
            ((++LineNumber))
            CurrentValueOnLine[LineNumber]="*** ${COMPOSE_ENV} ***"
            #DefaultValueOnLine[LineNumber]="*** ${COMPOSE_ENV} ***"
            LineColor[LineNumber]='\Z0'
            for VarName in "${AppVarGlobalList[@]}"; do
                ((++LineNumber))
                VarNameOnLine[LineNumber]="${VarName}"
                CurrentValueOnLine[LineNumber]="${VarName}=$(run_script 'env_get_literal' "${VarName}")"
                #DefaultValueOnLine[LineNumber]="${VarName}=$(run_script 'env_get_literal' "${VarName}")"
                LineColor[LineNumber]='\Z0\Zr'
            done
        fi
        if [[ -n ${AppVarEnvList[*]-} ]]; then
            if [[ ${LineNumber} != 0 ]]; then
                ((++LineNumber))
                CurrentValueOnLine[LineNumber]=""
                LineColor[LineNumber]='\Z0'
            fi
            ((++LineNumber))
            CurrentValueOnLine[LineNumber]="*** ${APP_ENV_FOLDER_NAME}/${appname}.env ***"
            for VarName in "${AppVarEnvList[@]}"; do
                ((++LineNumber))
                VarNameOnLine[LineNumber]="${appname}:${VarName}"
                CurrentValueOnLine[LineNumber]="${VarName}=$(run_script 'env_get_literal' "${appname}:${VarName}")"
                #DefaultValueOnLine[LineNumber]="${VarName}=$(run_script 'env_get_literal' "${appname}:${VarName}"")"
                LineColor[LineNumber]='\Z0\Zr'
            done
        fi
        for LineNumber in "${!CurrentValueOnLine[@]}"; do
            local PaddedLineNumber=""
            PaddedLineNumber="$(printf '%03d' "${LineNumber}")"
            LineOptions+=("${PaddedLineNumber}" "${LineColor[LineNumber]-}${CurrentValueOnLine[LineNumber]}")
        done
        local -a LineDialog=(
            --stdout
            --colors
            --title "${Title}"
            --cancel-button "Back"
            --menu "${AppName}" 0 0 0
            "${LineOptions[@]}"
        )
        while true; do
            local LineDialogButtonPressed=0
            LineChoice=$(dialog --default-item "${LineButtonPressed}" "${LineDialog[@]}") || LineDialogButtonPressed=$?
            case ${LineDialogButtonPressed} in
                "${DIALOG_OK}")
                    LineButtonPressed="${LineChoice}"
                    # shellcheck disable=SC2199 # Arrays implicitly concatenate in [[ ]]. Use a loop (or explicit * instead of @).
                    if [[ -n ${VarNameOnLine[${LineChoice}]-} ]]; then
                        run_script 'menu_value_prompt' "${VarNameOnLine[${LineChoice}]}"
                        break
                    fi
                    ;;
                "${DIALOG_CANCEL}" | "${DIALOG_ESC}")
                    return
                    ;;
                *)
                    if [[ -n ${DIALOG_BUTTONS[$LineDialogButtonPressed]-} ]]; then
                        clear
                        fatal "Unexpected dialog button '${DIALOG_BUTTONS[$LineDialogButtonPressed]}' pressed."
                    else
                        clear
                        fatal "Unexpected dialog button value'${LineDialogButtonPressed}' pressed."
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
