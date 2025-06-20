#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

apply_theme() {
    local ThemeName=${1-}
    if [[ -z ${ThemeName-} ]]; then
        if [[ ! -f ${MENU_INI_FILE} ]]; then
            cp "${THEME_FOLDER}/${MENU_INI_NAME}" "${MENU_INI_FILE}"
        fi
        ThemeName="$(run_script 'env_get' Theme "${MENU_INI_FILE}")"
    fi

    local ThemeFolder="${THEME_FOLDER}/${ThemeName}"
    local COLORS_INI_NAME="colors.ini"
    local ThemeFile="${ThemeFolder}/${COLORS_INI_NAME}"
    local DialogFile="${ThemeFolder}/${DIALOGRC_NAME}"
    if [[ ! -f ${ThemeFile} || ! -f ${DialogFile} ]]; then
        error "Theme ${ThemeName} does not exist."
        return
    fi

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

    DC=()
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
        ["WindowColsAdjust"]=5
        ["WindowRowsAdjust"]=4
        ["TextColsAdjust"]=4
        ["TextRowsAdjust"]=7
    )

    local -a VarList
    readarray -t VarList < <(run_script 'env_var_list' "${ThemeFile}")
    for VarName in "${VarList[@]-}"; do
        local Value
        Value="$(run_script 'env_get' "${VarName}" "${ThemeFile}")"
        Value="$(
            _B_="${_B_}" _C_="${_C_}" _G_="${_G_}" _K_="${_K_}" _M_="${_M_}" _R_="${_R_}" _W_="${_W_}" _Y_="${_Y_}" \
                _RV_="${_RV_}" _NRV_="${_NRV_}" _BD_="${_BD_}" _NBD_="${_NBD_}" _U_="${_U_}" _NU_="${_NU_}" _NC_="${_NC_}" \
                envsubst <<< "${Value}"
        )"
        DC["${VarName}"]="${Value}"
    done
    DC["ThemeName"]="${ThemeName}"
    DIALOGOPTS="--colors  --cr-wrap --no-collapse --backtitle ${DC[BackTitle]}${BACKTITLE}"

    local LineCharacters Scrollbar Shadow
    LineCharacters="$(run_script 'env_get' "LineCharacters" "${MENU_INI_FILE}")"
    Scrollbar="$(run_script 'env_get' "Scrollbar" "${MENU_INI_FILE}")"
    Shadow="$(run_script 'env_get' "Shadow" "${MENU_INI_FILE}")"

    if [[ ${LineCharacters^^} =~ ON|TRUE|YES ]]; then
        DIALOGOPTS+=" --lines"
    else
        DIALOGOPTS+=" --no-lines"
    fi
    if [[ ${Scrollbar^^} =~ ON|TRUE|YES ]]; then
        DIALOGOPTS+=" --scrollbar"
    else
        DIALOGOPTS+=" --no-scrollbar"
    fi
    if [[ ${Shadow^^} =~ ON|TRUE|YES ]]; then
        DIALOGOPTS+=" --shadow"
        DC["TextColsAdjust"]=$((DC["TextColsAdjust"] + 1))
        DC["TextRowsAdjust"]=$((DC["TextRowsAdjust"] + 1))
    else
        DIALOGOPTS+=" --no-shadow"
    fi
    export DIALOGOPTS DC
    cp "${DialogFile}" "${DIALOGRC}"
    run_script 'env_set' Theme "${ThemeName}" "${MENU_INI_FILE}"
}

test_apply_theme() {
    warn "CI does not test apply_theme."
}
