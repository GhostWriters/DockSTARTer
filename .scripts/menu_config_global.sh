#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_config_global() {
    local Title="Global Variables"

    local -a VarList
    readarray -t VarList < <(run_script 'env_var_list' "${COMPOSE_ENV_DEFAULT_FILE}")

    local LastVarChoice=""
    while true; do
        local -a VarOptions=()
        if [[ -n ${VarList[*]} ]]; then
            for VarName in "${VarList[@]}"; do
                local CurrentValue
                CurrentValue=$(run_script 'env_get_literal' "${VarName}")
                VarOptions+=("${VarName}" "${VarName}=${CurrentValue}")
            done
        fi
        local -a VarDialog=(
            --stdout
            --title "${Title}"
            --cancel-button "Back"
            --no-tags
            --menu "${COMPOSE_ENV}" 0 0 0
            "${VarOptions[@]}"
        )
        while true; do
            local -i VarDialogButtonPressed=0
            VarChoice=$(dialog --default-item "${LastVarChoice}" "${VarDialog[@]}") || VarDialogButtonPressed=$?
            case ${DIALOG_BUTTONS[VarDialogButtonPressed]-} in
                OK)
                    LastVarChoice="${VarChoice}"
                    # shellcheck disable=SC2199 # Arrays implicitly concatenate in [[ ]]. Use a loop (or explicit * instead of @).
                    if [[ " ${VarList[@]} " == *" ${VarChoice} "* ]]; then
                        run_script 'menu_value_prompt' "${VarChoice}"
                        break
                    fi
                    ;;
                CANCEL | ESC)
                    return
                    ;;
                *)
                    if [[ -n ${DIALOG_BUTTONS[VarDialogButtonPressed]-} ]]; then
                        clear
                        fatal "Unexpected dialog button '${DIALOG_BUTTONS[VarDialogButtonPressed]}' pressed."
                    else
                        clear
                        fatal "Unexpected dialog button value'${VarDialogButtonPressed}' pressed."
                    fi
                    ;;
            esac
        done
    done
}

test_menu_config_global() {
    # run_script 'menu_config_global'
    warn "CI does not test menu_config_global."
}
