#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_add_app() {
    local Title="Add Application"

    local AppNameMaxLength=256
    local AppNameNone="${DC[Highlight]}[*NONE*]"

    local AppName=""
    #local BaseAppName InstanceName
    while true; do
        local AppNameHeading="${AppName}"
        if ! run_script 'appname_is_valid' "${AppName}"; then
            AppNameHeading="${AppNameNone}"
        fi
        local InputValueText
        Heading="$(run_script 'menu_heading' "${AppNameHeading}")"
        InputValueText="${Heading}\n\nWhat application would you like add?\n"
        local ValueOptions
        ValueOptions=(
            "" 1 1
            "${AppName}" 1 1
            "${AppNameMaxLength}" "${AppNameMaxLength}"
        )
        local -a InputValueDialog=(
            --stdout
            --title "${DC["Title"]}${Title}"
            --max-input 256
            --form "${InputValueText}"
            "$((LINES - DC["WindowRowsAdjust"]))" "$((COLUMNS - DC["WindowColsAdjust"]))" 0
            "${ValueOptions[@]}"
        )
        local InputValueDialogButtonPressed=0
        AppName=$(_dialog_ "${InputValueDialog[@]}") || InputValueDialogButtonPressed=$?
        case ${DIALOG_BUTTONS[InputValueDialogButtonPressed]-} in
            OK)
                # Sanitize the input
                local CleanAppName
                CleanAppName="$(tr -c '[:alnum:]' ' ' <<< "${AppName}" | xargs)"
                if [[ -z ${CleanAppName//_/} ]]; then
                    AppName=''
                    continue
                fi
                BaseAppName="${CleanAppName%% *}"
                InstanceName="${CleanAppName#"${BaseAppName}"}"
                InstanceName="${InstanceName// /}"
                CleanAppName="${BaseAppName}"
                if [[ -n ${InstanceName} ]]; then
                    CleanAppName+="__${InstanceName}"
                fi
                AppName="${CleanAppName}"

                local ErrorMessage=''
                if run_script 'appname_is_valid' "${AppName}"; then
                    AppName="$(run_script 'app_nicename' "${AppName}")"
                    AppNameHeading="${AppName}"
                else
                    AppNameHeading="${AppNameNone}"
                    ErrorMessage="The application name ${DC[Highlight]}${AppName}${DC[NC]} is not a valid name.\n\n Please input another application name."
                fi
                if [[ -n ${ErrorMessage} ]]; then
                    Heading="$(run_script 'menu_heading' "${AppNameHeading}")"
                    dialog_error "${Title}" "${Heading}\n\n${ErrorMessage}"
                    continue
                fi
                Heading="$(run_script 'menu_heading' "${AppNameHeading}")"
                if ! run_script 'app_is_builtin' "${AppName}"; then
                    local Question
                    Question="Create user defined application ${DC[Highlight]}${AppName}${DC[NC]}?\n"
                    Heading="$(run_script 'menu_heading' "${AppNameHeading}")"
                    if run_script 'question_prompt' N "${Heading}\n\n${Question}" "Create Application" "" "User Defined" "Back"; then
                        Heading="$(run_script 'menu_heading' "${AppNameHeading}")"
                        dialog_success "Adding User Defined Application" "${Heading}" "${DIALOGTIMEOUT}"
                        run_script 'menu_add_var' "${AppName}"
                        return
                    fi
                else
                    local Question
                    Question="Application ${DC[Highlight]}${AppName}${DC[NC]} can be added as a built-in application.\n\nCreate ${DC[Highlight]}${AppName}${DC[NC]} as a ${DC[Highlight]}Built In${DC[NC]} or a ${DC[Highlight]}User Defined${DC[NC]} application?\n"
                    Heading="$(run_script 'menu_heading' "${AppNameHeading}")"
                    local -a YesNoDialog=(
                        --title "${Title}"
                        --no-collapse
                        --extra-button
                        --yes-label "Built In"
                        --extra-label "User Defined"
                        --no-label "Back"
                        --yesno "${Heading}\n\n${Question}"
                        "$((LINES - DC["WindowRowsAdjust"]))" "$((COLUMNS - DC["WindowColsAdjust"]))"
                    )
                    local -i YesNoDialogButtonPressed=0
                    _dialog_ "${YesNoDialog[@]}" || YesNoDialogButtonPressed=$?
                    case ${DIALOG_BUTTONS[YesNoDialogButtonPressed]-} in
                        OK) # Built In
                            Heading="$(run_script 'menu_heading' "${AppNameHeading}")"
                            coproc {
                                dialog_pipe "${DC[TitleSuccess]}Adding Built In Application" "${Heading}\n\n${DC[Subtitle]}Adding application:\n${DC[CommandLine]} ${APPLICATION_COMMAND} --add ${AppName}" "${DIALOGTIMEOUT}"
                            }
                            local -i DialogBox_PID=${COPROC_PID}
                            local -i DialogBox_FD="${COPROC[1]}"
                            {
                                run_script 'env_backup'
                                run_script 'appvars_create' "${AppName}"
                                run_script 'env_update'
                            } >&${DialogBox_FD} 2>&1
                            exec {DialogBox_FD}<&-
                            wait ${DialogBox_PID}
                            return
                            ;;
                        EXTRA) # User Defined
                            Heading="$(run_script 'menu_heading' "${AppNameHeading}")"
                            dialog_success "${DC[TitleSuccess]}Adding User Defined Application" "${Heading}" "${DIALOGTIMEOUT}"
                            run_script 'menu_add_var' "${AppName}"
                            return
                            ;;
                        CANCEL | ESC) # Back
                            ;;
                        *)
                            if [[ -n ${DIALOG_BUTTONS[YesNoDialogButtonPressed]-} ]]; then
                                fatal "Unexpected dialog button '${F[C]}${DIALOG_BUTTONS[YesNoDialogButtonPressed]}${NC}' pressed in menu_add_app."
                            else
                                fatal "Unexpected dialog button value '${F[C]}${YesNoDialogButtonPressed}${NC}' pressed in menu_add_app."
                            fi
                            ;;
                    esac
                fi
                ;;
            CANCEL | ESC)
                return
                ;;
            *)
                if [[ -n ${DIALOG_BUTTONS[InputValueDialogButtonPressed]-} ]]; then
                    fatal "Unexpected dialog button '${F[C]}${DIALOG_BUTTONS[InputValueDialogButtonPressed]}${NC}' pressed in menu_add_app."
                else
                    fatal "Unexpected dialog button value '${F[C]}${InputValueDialogButtonPressed}${NC}' pressed in menu_add_app."
                fi
                ;;
        esac
    done
}
test_menu_add_app() {
    warn "CI does not test menu_add_app."
}
