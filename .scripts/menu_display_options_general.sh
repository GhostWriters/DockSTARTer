#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_display_options_general() {
    if [[ ${CI-} == true ]]; then
        return
    fi

    local Title="General Display Options"

    #run_script 'apply_theme'

    local DrawLineOption="Draw Lines"
    local ShowBordersOption="Show Borders"
    local ShowScrollbarOption="Show Scrollbar"
    local ShowShadowOption="Show Shadow"

    local -A OptionDescription OptionVariable

    OptionDescription["${DrawLineOption}"]="Use line drawing characters"
    OptionDescription["${ShowBordersOption}"]="Show borders in dialog boxes"
    OptionDescription["${ShowScrollbarOption}"]="Show a scrollbar in dialog boxes"
    OptionDescription["${ShowShadowOption}"]="Show a shadow under the dialog boxes"

    OptionVariable["${DrawLineOption}"]="LineCharacters"
    OptionVariable["${ShowBordersOption}"]="Borders"
    OptionVariable["${ShowScrollbarOption}"]="Scrollbar"
    OptionVariable["${ShowShadowOption}"]="Shadow"

    while true; do
        local EnabledOptions=()
        local Opts=()
        for Option in "${DrawLineOption}" "${ShowBordersOption}" "${ShowScrollbarOption}" "${ShowShadowOption}"; do
            local Value
            Value="$(run_script 'config_get' "${OptionVariable["${Option}"]}" "${MENU_INI_FILE}")"
            if [[ ${Value^^} =~ ON|TRUE|YES ]]; then
                EnabledOptions+=("${Option}")
                Opts+=("${Option}" "${OptionDescription["${Option}"]}" ON)
            else
                Opts+=("${Option}" "${OptionDescription["${Option}"]}" OFF)
            fi
        done
        local -a ChoiceDialog=(
            --output-fd 1
            --title "${DC["Title"]}${Title}"
            --ok-label "Select"
            --cancel-label "Back"
            --separate-output
            --checklist "Choose the options to enable." 0 0 0
            "${Opts[@]}"
        )
        local Choices
        local -i DialogButtonPressed=0
        Choices=$(_dialog_ "${ChoiceDialog[@]}") || DialogButtonPressed=$?
        case ${DIALOG_BUTTONS[DialogButtonPressed]-} in
            OK)
                local -a ChoicesArray OptionsToTurnOff OptionsToTurnOn
                readarray -t ChoicesArray <<< "${Choices}"
                readarray -t OptionsToTurnOff < <(
                    printf '%s\n' "${EnabledOptions[@]}" "${ChoicesArray[@]}" "${ChoicesArray[@]}" | sort -f | uniq -u
                )
                readarray -t OptionsToTurnOn < <(
                    printf '%s\n' "${EnabledOptions[@]}" "${EnabledOptions[@]}" "${ChoicesArray[@]}" | sort -f | uniq -u
                )
                if [[ -n ${OptionsToTurnOff[*]-} || ${OptionsToTurnOn[*]-} ]]; then
                    if [[ -n ${OptionsToTurnOff[*]-} ]]; then
                        for Option in "${OptionsToTurnOff[@]}"; do
                            run_script 'config_set' "${OptionVariable["${Option}"]}" OFF "${MENU_INI_FILE}"
                        done
                    fi
                    if [[ -n ${OptionsToTurnOn[*]-} ]]; then
                        for Option in "${OptionsToTurnOn[@]}"; do
                            run_script 'config_set' "${OptionVariable["${Option}"]}" ON "${MENU_INI_FILE}"
                        done
                    fi
                    run_script 'apply_theme'
                fi
                ;;
            CANCEL | ESC)
                return
                ;;
            *)
                if [[ -n ${DIALOG_BUTTONS[DialogButtonPressed]-} ]]; then
                    fatal "Unexpected dialog button '${DIALOG_BUTTONS[DialogButtonPressed]}' pressed in menu_display_options_general."
                else
                    fatal "Unexpected dialog button value '${DialogButtonPressed}' pressed in menu_display_options_general."
                fi
                ;;
        esac
    done
}

test_menu_display_options_general() {
    warn "CI does not test menu_display_options_general."
}
