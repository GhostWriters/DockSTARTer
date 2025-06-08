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
        AppName=$(dialog "${InputValueDialog[@]}") || InputValueDialogButtonPressed=$?
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

                AppNameHeading="${AppName}"
                local ErrorMessage=''
                if run_script 'appname_is_valid' "${AppName}"; then
                    dialog_message "${AppName} Valid"
                    AppName="$(run_script 'app_nicename' "${AppName}")"
                    dialog_message "${AppName} nicename"
                    if run_script 'app_is_referenced' "${AppName}"; then
                        dialog_message "${AppName} Referenced"
                        ErrorMessage="The application ${DC[Highlight]}${AppName}${DC[NC]} is already installed.\n\n Please input another application name."
                    fi
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
                    if run_script 'question_prompt' N "${Heading}\n\n${Question}" "${DC["TitleWarning"]}Create Application" "" "User Defined" "Back"; then
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
                        --title "${DC[TitleWarning]}${Title}"
                        --no-collapse
                        --extra-button
                        --yes-label "Built In"
                        --extra-label "User Defined"
                        --no-label "Back"
                        --yesno "${Heading}\n\n${Question}"
                        "$((LINES - DC["WindowRowsAdjust"]))" "$((COLUMNS - DC["WindowColsAdjust"]))"
                    )
                    local -i YesNoDialogButtonPressed=0
                    dialog "${YesNoDialog[@]}" || YesNoDialogButtonPressed=$?
                    case ${DIALOG_BUTTONS[YesNoDialogButtonPressed]-} in
                        OK) # Built In
                            Heading="$(run_script 'menu_heading' "${AppNameHeading}")"
                            {
                                run_script 'appvars_create' "${AppName}"
                            } |& dialog_pipe "Adding Built In Application" "${Heading}\n\n" "${DIALOGTIMEOUT}"
                            return
                            ;;
                        EXTRA) # User Defined
                            Heading="$(run_script 'menu_heading' "${AppNameHeading}")"
                            dialog_success "Adding User Defined Application" "${Heading}" "${DIALOGTIMEOUT}"
                            run_script 'menu_add_var' "${AppName}"
                            return
                            ;;
                        CANCEL | ESC) # Back
                            ;;
                        *)
                            if [[ -n ${DIALOG_BUTTONS[YesNoDialogButtonPressed]-} ]]; then
                                clear
                                fatal "Unexpected dialog button '${DIALOG_BUTTONS[YesNoDialogButtonPressed]}' pressed."
                            else
                                clear
                                fatal "Unexpected dialog button value '${YesNoDialogButtonPressed}' pressed."
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
                    clear
                    fatal "Unexpected dialog button '${DIALOG_BUTTONS[InputValueDialogButtonPressed]}' pressed."
                else
                    clear
                    fatal "Unexpected dialog button value '${InputValueDialogButtonPressed}' pressed."
                fi
                ;;
        esac
    done
}
test_menu_add_app() {
    warn "CI does not test menu_add_app."
}
