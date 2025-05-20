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

    local AddVariableText='<ADD VARIABLE>'

    #run_script_dialog "${Title}" "Creating variables for ${AppName}" 1 \
    #    'appvars_create' "${APPNAME}"

    local DefaultGlobalEnvFile
    DefaultGlobalEnvFile="$(run_script 'app_instance_file' "${appname}" ".global.env")"
    local CurrentGlobalEnvFile
    CurrentGlobalEnvFile=$(mktemp)

    local DefaultAppEnvFile
    DefaultAppEnvFile="$(run_script 'app_instance_file' "${appname}" ".app.env")"
    local CurrentAppEnvFile
    CurrentAppEnvFile=$(mktemp)

    local AppIsDisabled=''
    local AppIsDepreciated=''
    local AppIsUserDefined=''
    #local VarIsUserDefined='Y'
    if run_script 'app_is_builtin' "${appname}"; then
        if run_script 'app_is_disabled' "${appname}"; then
            AppIsDisabled='Y'
        fi
        if run_script 'app_is_depreciated' "${appname}"; then
            AppIsDepreciated='Y'
        fi
    else
        AppIsUserDefined='Y'
    fi

    local AppNameHeading="Application: ${DC[Heading]}${AppName}${DC[NC]}"
    if [[ ${AppIsUserDefined} == 'Y' ]]; then
        AppNameHeading="${AppNameHeading} ${DC[HeadingTag]}(User Defined)${DC[NC]}"
    elif [[ ${AppIsDepreciated} == 'Y' ]]; then
        AppNameHeading="${AppNameHeading} ${DC[HeadingTag]}[*DEPRECIATED*]${DC[NC]}"
    fi
    if [[ ${AppIsDisabled} == 'Y' ]]; then
        AppNameHeading="${AppNameHeading} ${DC[HeadingTag]}(Disabled)${DC[NC]}"
    fi

    local LastLineChoice=""
    while true; do
        local -a LineOptions=()
        local -a VarNameOnLine=()
        local -a CurrentValueOnLine=()
        local -a LineColor=()
        local -i LineNumber=0
        local FirstVarLine
        ((++LineNumber))
        LineColor[LineNumber]="${DC[LineHeading]}"
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
                LineColor[LineNumber]="${DC[LineVar]}"
                VarNameOnLine[LineNumber]="${VarName}"
                if [[ -z ${FirstVarLine-} ]]; then
                    FirstVarLine=${LineNumber}
                fi
            elif (grep -q -P '^\s*#' <<< "${line}"); then
                # Line is a comment
                LineColor[LineNumber]="${DC[LineComment]}"
            else
                # Line is an unknowwn line
                LineColor[LineNumber]="${DC[LineAddVariable]}"
            fi
        done
        ((LineNumber++))
        local AddGlobalVariableLineNumber=${LineNumber}
        CurrentValueOnLine[LineNumber]="${AddVariableText}"
        LineColor[LineNumber]="${DC[LineAddVariable]}"
        ((++LineNumber))
        CurrentValueOnLine[LineNumber]=""
        LineColor[LineNumber]="${DC[LineOther]}"

        ((++LineNumber))
        CurrentValueOnLine[LineNumber]="*** $(run_script 'app_env_file' "${appname}") ***"
        LineColor[LineNumber]="${DC[LineHeading]}"
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
                LineColor[LineNumber]="${DC[LineVar]}"
                VarNameOnLine[LineNumber]="${appname}:${VarName}"
                if [[ -z ${FirstVarLine-} ]]; then
                    FirstVarLine=${LineNumber}
                fi
            elif (grep -q -P '^\s*#' <<< "${line}"); then
                # Line is a comment
                LineColor[LineNumber]="${DC[LineComment]}"
            else
                # Line is an unknowwn line
                LineColor[LineNumber]="${DC[LineOther]}"
            fi
        done
        ((LineNumber++))
        local AddAppEnvVariableLineNumber=${LineNumber}
        CurrentValueOnLine[LineNumber]="${AddVariableText}"
        LineColor[LineNumber]="${DC[LineAddVariable]}"

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
            --menu "\n${AppNameHeading}" 0 0 0
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
                        break
                    elif [[ ${LineNumber} == "${AddAppEnvVariableLineNumber}" ]]; then
                        run_script 'menu_add_var' "${appname}:"
                        break
                    elif [[ -n ${VarNameOnLine[LineNumber]-} ]]; then
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
    rm -f "${CurrentGlobalEnvFile}" ||
        warn "Failed to remove temporary .env file.\nFailing command: ${F[C]}rm -f \"${CurrentGlobalEnvFile}\""
    rm -f "${CurrentAppEnvFile}" ||
        warn "Failed to remove temporary ${appname}.env file.\nFailing command: ${F[C]}rm -f \"${CurrentAppEnvFile}\""

}

test_menu_app_vars() {
    # run_script 'menu_app_vars'
    warn "CI does not test menu_app_vars."
}
