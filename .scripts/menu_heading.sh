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

    local AppIsDepreciated AppIsDisabled AppIsUserDefined VarIsUserDefined
    local VarFile
    local CleanVarName="${VarName}"
    if [[ -n ${AppName-} ]]; then
        AppName=$(run_script 'app_nicename' "${AppName}")
        local DefaultVarFile
        if [[ -n ${VarName-} ]]; then
            if [[ ${VarName} == *":"* ]]; then
                CleanVarName="${VarName#*:}"
                VarFile="$(run_script 'app_env_file' "${AppName}")"
                DefaultVarFile="$(run_script 'app_instance_file' "${AppName}" ".app.env")"
            else
                VarFile="${COMPOSE_ENV}"
                DefaultVarFile="$(run_script 'app_instance_file' "${AppName}" ".global.env")"
            fi
        fi
        if run_script 'app_is_user_defined' "${AppName}"; then
            AppIsUserDefined='Y'
            VarIsUserDefined='Y'
        else
            if run_script 'app_is_disabled' "${AppName}"; then
                AppIsDisabled='Y'
            fi
            if run_script 'app_is_depreciated' "${AppName}"; then
                AppIsDepreciated='Y'
            fi
            if [[ -n ${VarName-} ]] && ! run_script 'env_var_exists' "${CleanVarName}" "${DefaultVarFile}"; then
                VarIsUserDefined='Y'
            fi
        fi
    elif [[ -n ${VarName-} ]]; then
        VarFile="${COMPOSE_ENV}"
        DefaultVarFile="${COMPOSE_ENV_DEFAULT_FILE}"
        if ! run_script 'env_var_exists' "${CleanVarName}" "${DefaultVarFile}"; then
            VarIsUserDefined='Y'
        fi
    else
        VarFile="${COMPOSE_ENV}"
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
                if [[ -n ${CleanVarName-} ]]; then
                    Heading[Variable]="${DC[NC]}${Label[Variable]}${Highlight}${CleanVarName}${DC[NC]}"
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
