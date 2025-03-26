#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_value_prompt() {
    local VarName=${1-}
    local Title="Variable Value - ${VarName}"

    local CURRENT_VAL
    CURRENT_VAL=$(run_script 'env_get' "${VarName}")

    local APPNAME
    APPNAME=$(run_script 'varname_to_appname' "${VarName}")
    APPNAME=${APPNAME^^}
    local appname=${appname,,}
    local APP_FOLDER="${SCRIPTPATH}/compose/.apps/${appname}"
    local APP_DEFAULT_GLOBAL_ENV_FILE="${APP_FOLDER}/.env"

    local DEFAULT_VAL
    DEFAULT_VAL=$(run_script 'env_get' "${VarName}" "${COMPOSE_ENV_DEFAULT_FILE}")
    if [[ -z ${DEFAULT_VAL} ]]; then
        DEFAULT_VAL=$(run_script 'env_get' "${VarName}" "${APP_DEFAULT_GLOBAL_ENV_FILE}")
    fi

    local HOME_VAL
    local SYSTEM_VAL
    local ValueDescription
    local ValueOptions=()
    ValueOptions+=("Keep Current" "${CURRENT_VAL}")

    case "${VarName}" in
        DOCKER_GID)
            SYSTEM_VAL=$(cut -d: -f3 < <(getent group docker))
            ValueOptions+=("Use System" "${SYSTEM_VAL}")
            ;;
        DOCKER_HOSTNAME)
            SYSTEM_VAL=${HOSTNAME}
            ValueOptions+=("Use System" "${SYSTEM_VAL}")
            ;;
        DOCKER_VOLUME_CONFIG)
            HOME_VAL="${DETECTED_HOMEDIR}/.config/appdata"
            ValueOptions+=("Use Home" "${HOME_VAL}")
            ;;
        DOCKER_VOLUME_STORAGE)
            HOME_VAL="${DETECTED_HOMEDIR}/storage"
            ValueOptions+=("Use Home" "${HOME_VAL}")
            ;;
        PGID)
            SYSTEM_VAL=${DETECTED_PGID}
            ValueOptions+=("Use System" "${SYSTEM_VAL}")
            ;;
        PUID)
            SYSTEM_VAL=${DETECTED_PUID}
            ValueOptions+=("Use System" "${SYSTEM_VAL}")
            ;;
        TZ)
            SYSTEM_VAL=$(cat /etc/timezone)
            ValueOptions+=("Use System" "${SYSTEM_VAL}")
            ;;
        *)
            ValueOptions+=("Use Default" "${DEFAULT_VAL}")
            ;;
    esac

    ValueOptions+=("Enter New" "")

    case "${VarName}" in
        DOCKER_GID)
            ValueDescription='\n\n This should be the Docker group ID. If you are unsure, select Use System.'
            ;;
        DOCKER_HOSTNAME)
            ValueDescription='\n\n This should be your system hostname. If you are unsure, select Use System.'
            ;;
        PGID)
            ValueDescription='\n\n This should be your user group ID. If you are unsure, select Use System.'
            ;;
        PUID)
            ValueDescription='\n\n This should be your user account ID. If you are unsure, select Use System.'
            ;;
        TZ)
            ValueDescription='\n\n If this is not the correct timezone please exit and set your system timezone.'
            ;;
        "${APPNAME}__ENABLED")
            ValueDescription='\n\n Must be true or false.'
            ;;
        "${APPNAME}__NETWORK_MODE")
            ValueDescription='\n\n Network Mode is usually left blank but can also be bridge, host, none, service: <APPNAME>, or container: <APPNAME>.'
            ;;
        "${APPNAME}__PORT_"*)
            ValueDescription='\n\n Must be an unused port between 0 and 65535.'
            ;;
        "${APPNAME}__RESTART")
            ValueDescription='\n\n Restart is usually unless-stopped but can also be no, always, or on-failure.'
            ;;
        "${APPNAME}__TAG")
            ValueDescription='\n\n Tag is usually latest but can also be other values based on the image.'
            ;;
        "${APPNAME}__VOLUME_"*)
            ValueDescription='\n\n If the directory selected does not exist we will attempt to create it.'
            ;;
        *)
            ValueDescription=""
            ;;
    esac

    if [[ -n ${SYSTEM_VAL-} ]]; then
        ValueDescription="\n\n System detected values are recommended.${ValueDescription}"
    fi

    local SELECT_DIALOG_BUTTON_PRESSED
    local SelectedValue
    if [[ ${CI-} == true ]]; then
        SELECT_DIALOG_BUTTON_PRESSED=${DIALOG_OK}
        SelectedValue="Keep Current"
    else
        local -a SelectedValueDialog=(
            --clear
            --stdout
            --title "${Title}"
            --menu "What would you like set for ${VarName}?${ValueDescription}"
            0 0 0
            "${ValueOptions[@]}"
        )
        SELECT_DIALOG_BUTTON_PRESSED=0 && SelectedValue=$(dialog "${SelectedValueDialog[@]}") || SELECT_DIALOG_BUTTON_PRESSED=$?
    fi

    local Input
    case ${SELECT_DIALOG_BUTTON_PRESSED} in
        "${DIALOG_OK}")
            case "${SelectedValue}" in
                "Keep Current")
                    Input=${CURRENT_VAL}
                    ;;
                "Use Home")
                    Input=${HOME_VAL}
                    ;;
                "Use Default")
                    Input=${DEFAULT_VAL}
                    ;;
                "Use System")
                    Input=${SYSTEM_VAL}
                    ;;
                "Enter New")
                    local INPUT_DIALOG_BUTTON_PRESSED
                    local -a InputDialog=(
                        --clear
                        --stdout
                        --title "${Title}"
                        --inputbox "What would you like set for ${VarName}?${ValueDescription}"
                        0 0
                        "${CURRENT_VAL}"
                    )
                    INPUT_DIALOG_BUTTON_PRESSED=0 && Input=$(dialog "${InputDialog[@]}") || INPUT_DIALOG_BUTTON_PRESSED=$?
                    case ${INPUT_DIALOG_BUTTON_PRESSED} in
                        "${DIALOG_OK}") ;;
                        "${DIALOG_CANCEL}" | "${DIALOG_ESC}")
                            unset Input
                            ;;
                        *)
                            if [[ -n ${DIALOG_BUTTONS[$INPUT_DIALOG_BUTTON_PRESSED]-} ]]; then
                                clear && fatal "Unexpected dialog button '${DIALOG_BUTTONS[$INPUT_DIALOG_BUTTON_PRESSED]}' pressed."
                            else
                                clear && fatal "Unexpected dialog button value '${INPUT_DIALOG_BUTTON_PRESSED}' pressed."
                            fi
                            ;;
                    esac
                    ;;
            esac
            ;;
        "${DIALOG_CANCEL}" | "${DIALOG_ESC}")
            #warn "Selection of ${VarName} was canceled."
            return 1
            ;;
        *)
            if [[ -n ${DIALOG_BUTTONS[$SELECT_DIALOG_BUTTON_PRESSED]-} ]]; then
                clear && fatal "Unexpected dialog button '${DIALOG_BUTTONS[$SELECT_DIALOG_BUTTON_PRESSED]}' pressed."
            else
                clear && fatal "Unexpected dialog button value' ${SELECT_DIALOG_BUTTON_PRESSED}' pressed."
            fi
            ;;
    esac

    if [[ -z ${Input-} ]]; then
        menu_value_prompt "${VarName}"
    else
        case "${VarName}" in
            "${APPNAME}__ENABLED")
                if [[ ${Input} == true ]] || [[ ${Input} == false ]]; then
                    run_script 'env_set' "${VarName}" "${Input}"
                else
                    dialog --clear --title "${Title}" --msgbox "${Input} is not true or false. Please try setting ${VarName} again." 0 0
                    menu_value_prompt "${VarName}"
                fi
                ;;
            "${APPNAME}__NETWORK_MODE")
                case "${Input}" in
                    "" | "bridge" | "host" | "none" | "service:"* | "container:"*)
                        run_script 'env_set' "${VarName}" "${Input}"
                        ;;
                    *)
                        dialog --clear --title "${Title}" --msgbox "${Input} is not a valid network mode. Please try setting ${VarName} again." 0 0
                        menu_value_prompt "${VarName}"
                        ;;
                esac
                ;;
            "${APPNAME}__PORT_"*)
                if [[ ${Input} =~ ^[0-9]+$ ]] || [[ ${Input} -ge 0 ]] || [[ ${Input} -le 65535 ]]; then
                    run_script 'env_set' "${VarName}" "${Input}"
                else
                    dialog --clear --title "${Title}" --msgbox "${Input} is not a valid port. Please try setting ${VarName} again." 0 0
                    menu_value_prompt "${VarName}"
                fi
                ;;
            "${APPNAME}__RESTART")
                case "${Input}" in
                    "no" | "always" | "on-failure" | "unless-stopped")
                        run_script 'env_set' "${VarName}" "${Input}"
                        ;;
                    *)
                        dialog --clear --title "${Title}" --msgbox "${Input} is not a valid restart value. Please try setting ${VarName} again." 0 0
                        menu_value_prompt "${VarName}"
                        ;;
                esac
                ;;
            "${APPNAME}__VOLUME_"*)
                if [[ ${Input} == "/" ]]; then
                    dialog --clear --title "${Title}" --msgbox "Cannot use / for ${VarName}. Please select another folder." 0 0
                    menu_value_prompt "${VarName}"
                elif [[ ${Input} == ~* ]]; then
                    local CORRECTED_DIR="${DETECTED_HOMEDIR}${Input#*~}"
                    if run_script 'question_prompt' Y "Cannot use the ~ shortcut in ${VarName}. Would you like to use ${CORRECTED_DIR} instead?" "${Title}"; then
                        run_script 'env_set' "${VarName}" "${CORRECTED_DIR}"
                        dialog --clear --title "${Title}" --msgbox "Returning to the previous menu to confirm selection." 0 0
                    else
                        dialog --clear --title "${Title}" --msgbox "Cannot use the ~ shortcut in ${VarName}. Please select another folder." 0 0
                    fi
                    menu_value_prompt "${VarName}"
                elif [[ -d ${Input} ]]; then
                    run_script 'env_set' "${VarName}" "${Input}"
                    if run_script 'question_prompt' Y "Would you like to set permissions on ${Input} ?" "${Title}"; then
                        run_script 'set_permissions' "${Input}"
                    fi
                else
                    if run_script 'question_prompt' Y "${Input} is not a valid path. Would you like to attempt to create it?" "${Title}"; then
                        mkdir -p "${Input}" || fatal "Failed to make directory.\nFailing command: ${F[C]}mkdir -p \"${Input}\""
                        run_script 'set_permissions' "${Input}"
                        run_script 'env_set' "${VarName}" "${Input}"
                        dialog --clear --title "${Title}" --msgbox "${Input} folder was created successfully." 0 0
                    else
                        dialog --clear --title "${Title}" --msgbox "${Input} is not a valid path. Please try setting ${VarName} again." 0 0
                        menu_value_prompt "${VarName}"
                    fi
                fi
                ;;
            P[GU]ID)
                if [[ ${Input} == "0" ]]; then
                    if run_script 'question_prompt' Y "Running as root is not recommended. Would you like to select a different ID?" "${Title}"; then
                        menu_value_prompt "${VarName}"
                    else
                        run_script 'env_set' "${VarName}" "${Input}"
                    fi
                elif [[ ${Input} =~ ^[0-9]+$ ]]; then
                    run_script 'env_set' "${VarName}" "${Input}"
                else
                    dialog --clear --title "${Title}" --msgbox "${Input} is not a valid ${VarName}. Please try setting ${VarName} again." 0 0
                    menu_value_prompt "${VarName}"
                fi
                ;;
            *)
                run_script 'env_set' "${VarName}" "${Input}"
                ;;
        esac
    fi
}

test_menu_value_prompt() {
    # run_script 'menu_value_prompt'
    warn "CI does not test menu_value_prompt."
}
