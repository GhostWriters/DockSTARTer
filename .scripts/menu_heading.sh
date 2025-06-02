#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_heading() {
    local AppName=${1-}
    local VarName=${2-}
    local OriginalValue=${3-}
    local CurrentValue=${4-}

    local -A Label=(
        [Application]="Application: "
        [Filename]="File: "
        [Variable]="Variable: "
        [OriginalValue]="Original Value: "
        [CurrentValue]="Current Value: "
    )
    local -A Tag=(
        [AppDepreciated]="${DC[HeadingTag]}[*DEPRECIATED*]${DC[NC]}"
        [AppDisabled]="${DC[HeadingTag]}(Disabled)${DC[NC]}"
        [AppUserDefined]="${DC[HeadingTag]}(User Defined)${DC[NC]}"
        [VarUserDefined]="${DC[HeadingTag]}(User Defined)${DC[NC]}"
    )
    local -i LabelWidth=0
    for LabelText in "${Label[@]}"; do
        if [[ ${#LabelText} -gt LabelWidth ]]; then
            LabelWidth=${#LabelText}
        fi
    done
    for LabelName in "${!Label[@]}"; do
        local LabelText="${Label["${LabelName}"]}"
        Label["${LabelName}"]="$(printf "%${LabelWidth}s" "${LabelText}")"
    done
    Indent="$(printf "%${LabelWidth}s" "")"
    local -A Heading=()

    local AppIsDepreciated AppIsDisabled AppIsUserDefined VarIsValid VarIsUserDefined
    local VarFile
    local DefaultVarFile

    if [[ ${AppName-} == ":"* ]]; then # ":AppName", using .env
        AppName="${AppName#:*}"
        VarFile="${COMPOSE_ENV}"
        DefaultVarFile="$(run_script 'app_instance_file' "${AppName}" ".global.env")"
    elif [[ ${AppName-} == *":" ]]; then # "AppName:", using appname.env
        AppName="${AppName%:*}"
        VarFile="$(run_script 'app_env_file' "${AppName}")"
        DefaultVarFile="$(run_script 'app_instance_file' "${AppName}" ".app.env")"
    fi
    if [[ -n ${VarName-} ]] && run_script 'varname_is_valid' "${VarName}"; then # "appname:varname", using appname.env
        VarIsValid='Y'
        if [[ ${VarName} == *":"* ]]; then
            AppName="${VarName%:*}"
            VarName="${VarName#*:}"
            VarFile="$(run_script 'app_env_file' "${AppName}")"
            DefaultVarFile="$(run_script 'app_instance_file' "${AppName}" ".app.env")"
        fi
        if [[ -z ${VarFile-} ]]; then
            VarFile="${COMPOSE_ENV}"
            DefaultVarFile="$(run_script 'app_instance_file' "${AppName}" ".global.env")"
        fi
    fi

    if [[ -n ${AppName-} ]]; then
        if run_script 'app_is_user_defined' "${AppName}"; then
            AppIsUserDefined='Y'
            if [[ -n ${VarIsValid-} ]]; then
                VarIsUserDefined='Y'
            fi
        else
            if run_script 'app_is_disabled' "${AppName}"; then
                AppIsDisabled='Y'
            fi
            if run_script 'app_is_depreciated' "${AppName}"; then
                AppIsDepreciated='Y'
            fi
            if [[ -n ${VarIsValid-} && -n ${DefaultVarFile-} ]] && ! run_script 'env_var_exists' "${VarName}" "${DefaultVarFile}"; then
                VarIsUserDefined='Y'
            fi
        fi
        AppName=$(run_script 'app_nicename' "${AppName}")
    else # Global File or Variable
        VarFile="${COMPOSE_ENV}"
        DefaultVarFile="${COMPOSE_ENV_DEFAULT_FILE}"
        if [[ -n ${VarIsValid-} ]] && ! run_script 'env_var_exists' "${VarName}" "${DefaultVarFile}"; then
            VarIsUserDefined='Y'
        fi
    fi

    local Highlight="${DC[HeadingValue]}"
    for LabelName in CurrentValue OriginalValue Variable Filename Application; do
        case "${LabelName}" in
            Application)
                if [[ -n ${AppName-} ]]; then
                    Heading[Application]="${DC[NC]}${Label[Application]}${Highlight}${AppName}${DC[NC]}"
                    if [[ ${AppIsDepreciated-} == "Y" ]]; then
                        Heading[Application]+=" ${DC[HeadingTag]}${Tag[AppDepreciated]}${DC[NC]}"
                    fi
                    if [[ ${AppIsDisabled-} == "Y" ]]; then
                        Heading[Application]+=" ${DC[HeadingTag]}${Tag[AppDisabled]}${DC[NC]}"
                    fi
                    if [[ ${AppIsUserDefined-} == "Y" ]]; then
                        Heading[Application]+=" ${DC[HeadingTag]}${Tag[AppUserDefined]}${DC[NC]}"
                    fi
                    Heading[Application]+="\n"

                    local AppDescription
                    AppDescription="$(run_script 'app_description' "${AppName}")"
                    local -i ScreenCols
                    ScreenCols=$(stty size | cut -d ' ' -f 2)
                    local -i TextWidth=$((ScreenCols - DC["WindowColsAdjust"] - DC["TextColsAdjust"] - LabelWidth))
                    local -a AppDesciptionArray
                    readarray -t AppDesciptionArray < <(fmt -w ${TextWidth} <<< "${AppDescription}")
                    Heading[Application]+="$(printf "${Indent}${DC[HeadingAppDescription]}%s${DC[NC]}\n" "${AppDesciptionArray[@]-}")"
                    Heading[Application]+="\n\n"
                    Highlight="${DC[Heading]}"
                fi
                ;;
            Filename)
                if [[ -n ${VarFile-} ]]; then
                    Heading[Filename]="${DC[NC]}${Label[Filename]}${Highlight}${VarFile}${DC[NC]}\n"
                    Highlight="${DC[Heading]}"
                fi
                ;;
            Variable)
                if [[ -n ${VarName-} ]]; then
                    Heading[Variable]="${DC[NC]}${Label[Variable]}${Highlight}${VarName}${DC[NC]}"
                    if [[ ${VarIsUserDefined-} == "Y" ]]; then
                        Heading[Variable]+=" ${DC[HeadingTag]}${Tag[VarUserDefined]}${DC[NC]}"
                    fi
                    Heading[Variable]+="\n"
                    Highlight="${DC[Heading]}"
                fi
                ;;
            OriginalValue)
                if [[ -n ${OriginalValue-} ]]; then
                    Heading[OriginalValue]="\n${Label[OriginalValue]}${Highlight}${OriginalValue}${DC[NC]}\n"
                    Highlight="${DC[Heading]}"
                fi
                ;;
            CurrentValue)
                if [[ -n ${CurrentValue-} ]]; then
                    Heading[CurrentValue]="${Label[OriginalValue]}${Highlight}${CurrentValue}${DC[NC]}\n"
                    Highlight="${DC[Heading]}"
                fi
                ;;
        esac
    done
    printf '%b' "${Heading[Application]-}${Heading[Filename]-}${Heading[Variable]-}${Heading[OriginalValue]-}${Heading[CurrentValue]-}"

}

test_menu_heading() {
    notice WATCHTOWER:
    run_script 'menu_heading' WATCHTOWER
    notice "WATCHTOWER WATCHTOWER__ENABLED:"
    run_script 'menu_heading' WATCHTOWER WATCHTOWER__ENABLED
    notice "'' DOCKER_VOLUME_STORAGE:"
    run_script 'menu_heading' '' DOCKER_VOLUME_STORAGE
    notice ":"
    run_script 'menu_heading'
    warn "CI does not test app_is_nondepreciated."
}
