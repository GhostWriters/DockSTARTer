#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

apply_theme() {
    local ThemeName=${1-}

    local DefaultThemes=(
        "${APPLICATION_NAME}"
        Default
    )

    local ThemeFile DialogFile
    local DefaultMenuIniFile="${THEME_FOLDER}/${MENU_INI_NAME}"
    if [[ -z ${ThemeName-} ]]; then
        if [[ ! -f ${MENU_INI_FILE} ]]; then
            cp "${DefaultMenuIniFile}" "${MENU_INI_FILE}"
        fi
        ThemeName="$(run_script 'config_get' Theme "${MENU_INI_FILE}")"
        if ! run_script 'theme_exists' "${ThemeName}"; then
            for Name in "${DefaultThemes[@]}"; do
                if run_script 'theme_exists' "${Name}"; then
                    ThemeName="${Name}"
                    break
                fi
            done
        fi
    fi

    if ! run_script 'theme_exists' "${ThemeName}"; then
        error "${APPLICATION_NAME} theme '${C["Theme"]}${ThemeName}${NC}' does not exist."
        return 1
    fi

    ThemeFile="${THEME_FOLDER}/${ThemeName}/${THEME_FILE_NAME}"
    DialogFile="${THEME_FOLDER}/${ThemeName}/${DIALOGRC_NAME}"

    local _B_='\Z4'   # Blue
    local _C_='\Z6'   # Cyan
    local _G_='\Z2'   # Green
    local _K_='\Z0'   # Black
    local _M_='\Z5'   # Magenta
    local _R_='\Z1'   # Red
    local _W_='\Z7'   # White
    local _Y_='\Z3'   # Yellow
    local _RV_='\Zr'  # Reverse
    local _NRV_='\ZR' # No Reverse
    local _BD_='\Zb'  # Bold
    local _NBD_='\ZB' # No Bold
    local _U_='\Zu'   # Underline
    local _NU_='\ZU'  # No Underline
    local _NC_='\Zn'  # No Color

    declare -Agx DC=()
    DC+=( # Dialog colors
        ["B"]="${_B_}"
        ["C"]="${_C_}"
        ["G"]="${_G_}"
        ["K"]="${_K_}"
        ["M"]="${_M_}"
        ["R"]="${_R_}"
        ["W"]="${_W_}"
        ["Y"]="${_Y_}"
        ["RV"]="${_RV_}"
        ["NRV"]="${_NRV_}"
        ["BD"]="${_BD_}"
        ["NBD"]="${_NBD_}"
        ["U"]="${_U_}"
        ["NU"]="${_NU_}"
        ["NC"]="${_NC_}"
    )
    DC+=( # Dialog positioning adjustment values
        ["WindowColsAdjust"]=4
        ["WindowRowsAdjust"]=4
        ["TextColsAdjust"]=4
        ["TextRowsAdjust"]=5
    )

    local -a VarList
    readarray -t VarList < <(run_script 'env_var_list' "${ThemeFile}")
    for VarName in "${VarList[@]-}"; do
        local Value
        Value="$(run_script 'config_get' "${VarName}" "${ThemeFile}")"
        Value="$(
            _B_="${_B_}" _C_="${_C_}" _G_="${_G_}" _K_="${_K_}" _M_="${_M_}" _R_="${_R_}" _W_="${_W_}" _Y_="${_Y_}" \
                _RV_="${_RV_}" _NRV_="${_NRV_}" _BD_="${_BD_}" _NBD_="${_NBD_}" _U_="${_U_}" _NU_="${_NU_}" _NC_="${_NC_}" \
                envsubst <<< "${Value}"
        )"
        DC["${VarName}"]="${Value}"
    done
    DC["ThemeName"]="${ThemeName}"
    local DialogOptions="--colors --output-fd 1 --cr-wrap --no-collapse"

    local LineCharacters Borders Scrollbar Shadow
    if run_script 'env_var_exists' Scrollbar "${MENU_INI_FILE}"; then
        Scrollbar="$(run_script 'config_get' Scrollbar "${MENU_INI_FILE}")"
    else
        Scrollbar="$(run_script 'config_get' Scrollbar "${DefaultMenuIniFile}")"
        run_script 'config_set' Scrollbar "${Scrollbar}" "${MENU_INI_FILE}"
    fi
    if run_script 'env_var_exists' Shadow "${MENU_INI_FILE}"; then
        Shadow="$(run_script 'config_get' Shadow "${MENU_INI_FILE}")"
    else
        Shadow="$(run_script 'config_get' Shadow "${DefaultMenuIniFile}")"
        run_script 'config_set' Shadow "${Shadow}" "${MENU_INI_FILE}"
    fi
    # Migrate old LineCharacters variable to Borders if Borders doesn't exist
    if run_script 'env_var_exists' Borders "${MENU_INI_FILE}"; then
        Borders="$(run_script 'config_get' Borders "${MENU_INI_FILE}")"
        if run_script 'env_var_exists' LineCharacters "${MENU_INI_FILE}"; then
            LineCharacters="$(run_script 'config_get' LineCharacters "${MENU_INI_FILE}")"
        else
            LineCharacters="$(run_script 'config_get' LineCharacters "${DefaultMenuIniFile}")"
            run_script 'config_set' LineCharacters "${LineCharacters}" "${MENU_INI_FILE}"
        fi
    else
        if run_script 'env_var_exists' LineCharacters "${MENU_INI_FILE}"; then
            Borders="$(run_script 'config_get' LineCharacters "${MENU_INI_FILE}")"
        else
            Borders="$(run_script 'config_get' Borders "${DefaultMenuIniFile}")"
        fi
        run_script 'config_set' Borders "${Borders}" "${MENU_INI_FILE}"
        LineCharacters="$(run_script 'config_get' LineCharacters "${DefaultMenuIniFile}")"
        run_script 'config_set' LineCharacters "${LineCharacters}" "${MENU_INI_FILE}"
    fi
    if [[ ${Borders^^} =~ ON|TRUE|YES ]]; then
        if [[ ! ${LineCharacters^^} =~ ON|TRUE|YES ]]; then
            DialogOptions+=" --ascii-lines"
        fi
    else
        DialogOptions+=" --no-lines"
    fi
    if [[ ${Scrollbar^^} =~ ON|TRUE|YES ]]; then
        DialogOptions+=" --scrollbar"
    else
        DialogOptions+=" --no-scrollbar"
    fi
    if [[ ${Shadow^^} =~ ON|TRUE|YES ]]; then
        DialogOptions+=" --shadow"
        DC["WindowColsAdjust"]=$((DC["WindowColsAdjust"] + 2))
        DC["WindowRowsAdjust"]=$((DC["WindowRowsAdjust"] + 1))
    else
        DialogOptions+=" --no-shadow"
    fi
    if [[ -z ${DIALOG_OPTIONS_FILE-} ]]; then
        declare -gx DIALOG_OPTIONS_FILE
        DIALOG_OPTIONS_FILE=$(mktemp -t "${APPLICATION_NAME}.${FUNCNAME[0]}.DIALOG_OPTIONS_FILE.XXXXXXXXXX")
    fi
    echo "${DialogOptions}" > "${DIALOG_OPTIONS_FILE}"

    cp "${DialogFile}" "${DIALOGRC}"
    run_script 'config_set' Theme "${ThemeName}" "${MENU_INI_FILE}"
    sort -o "${MENU_INI_FILE}" "${MENU_INI_FILE}"
}

test_apply_theme() {
    warn "CI does not test apply_theme."
}
