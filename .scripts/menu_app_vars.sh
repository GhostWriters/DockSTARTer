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
            dialog --clear --title "${Title}" --msgbox "${Message}" 0 0
        fi
        return
    fi

    run_script 'appvars_create' "${APPNAME}"

    local AppVarGlobalList
    local AppVarEnvList
    AppVarGlobalList=$(run_script 'env_list_app_global_defaults' "${AppName}")
    AppVarEnvList=$(run_script 'env_list_app_env_defaults' "${AppName}")
    if [[ -z ${AppVarGlobalList} && -z ${AppVarEnvList} ]]; then
        local Message="Application '${AppName} has no variables."
        if [[ ${CI-} == true ]]; then
            warn "${Message}"
        else
            dialog --clear --title "${Title}" --msgbox "${Message}" 0 0
        fi
        return
    fi

    local LastAppVarChoice=""
    while true; do
        local -a AppVarOptions=()
        if [[ -n ${AppVarGlobalList} ]]; then
            AppVarOptions+=("*** ${COMPOSE_ENV} ***" "*** ${COMPOSE_ENV} ***")
            for VarName in ${AppVarGlobalList}; do
                local CurrentValue
                CurrentValue=$(run_script 'env_get_literal' "${VarName}")
                AppVarOptions+=("${VarName}" "${VarName}=${CurrentValue}")
            done
        fi
        if [[ -n ${AppVarEnvList} ]]; then
            if [[ -n ${AppVarOptions[*]-} ]]; then
                AppVarOptions+=(" " "")
            fi
            AppVarOptions+=("*** ${APP_ENV_FOLDER_NAME}/${appname}.env ***" "*** ${APP_ENV_FOLDER_NAME}/${appname}.env ***")
            for VarName in ${AppVarEnvList}; do
                local CurrentValue
                CurrentValue=$(run_script 'env_get_literal' "${appname}:${VarName}")
                AppVarOptions+=("${appname}:${VarName}" "${VarName}=${CurrentValue}")
            done
        fi
        local -a AppVarDialog=(
            --clear
            --stdout
            --title "${Title}"
            --cancel-button "Back"
            --no-tags
            --menu "${AppName}" 0 0 0
            "${AppVarOptions[@]}"
        )
        while true; do
            local AppVarDialogButtonPressed=0
            AppVarChoice=$(dialog --default-item "${LastAppVarChoice}" "${AppVarDialog[@]}") || AppVarDialogButtonPressed=$?
            case ${AppVarDialogButtonPressed} in
                "${DIALOG_OK}")
                    LastAppVarChoice="${AppVarChoice}"
                    if [[ " ${AppVarGlobalList} ${AppVarEnvList}" =~ \b"${AppVarChoice}"\b ]]; then
                        run_script 'menu_value_prompt' "${AppVarChoice}"
                    fi
                    ;;
                "${DIALOG_CANCEL}" | "${DIALOG_ESC}")
                    return
                    ;;
                *)
                    if [[ -n ${DIALOG_BUTTONS[$AppVarDialogButtonPressed]-} ]]; then
                        clear
                        fatal "Unexpected dialog button '${DIALOG_BUTTONS[$AppVarDialogButtonPressed]}' pressed."
                    else
                        clear
                        fatal "Unexpected dialog button value'${AppVarDialogButtonPressed}' pressed."
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
