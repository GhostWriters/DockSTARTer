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
    local ColorFile="${ThemeFolder}/${COLORS_INI_NAME}"
    if [[ ! -d ${ThemeFolder} && ! -f ${ColorFile} && ! -f ${ThemeFolder}/.dialogrc ]]; then
        error "Theme ${ThemeName} does not exist."
        return
    fi

    run_script 'env_set' Theme "${ThemeName}" "${MENU_INI_FILE}"
    cp "${ThemeFolder}"/.dialogrc "${SCRIPTPATH}"/.dialogrc

    local B='\Z4'   # Blue
    local C='\Z6'   # Cyan
    local G='\Z2'   # Green
    local K='\Z0'   # Black
    local M='\Z5'   # Magenta
    local R='\Z1'   # Red
    local W='\Z7'   # White
    local Y='\Z3'   # Yellow
    local RV='\Zr'  # Reverse
    local NRV='\ZR' # No Reverse
    local BD='\Zb'  # Bold
    local NBD='\ZB' # No Bold
    local U='\Zu'   # Underline
    local NU='\ZU'  # No Underline
    local NC='\Zn'  # No Color

    # shellcheck disable=SC2016 # Expressions don't expand in single quotes, use double quotes for that.
    local ColorVars='$B,$C,$G,$K,$M,$R,$W,$Y,$RV,$NVR,$BD,$U,$NU,$NC'

    DC=()
    DC+=( # Dialog colors
        ["B"]="${B}"
        ["C"]="${C}"
        ["G"]="${G}"
        ["K"]="${K}"
        ["M"]="${M}"
        ["R"]="${R}"
        ["W"]="${W}"
        ["Y"]="${Y}"
        ["RV"]="${RV}"
        ["NRV"]="${NRV}"
        ["BD"]="${BD}"
        ["NBD"]="${NBD}"
        ["U"]="${U}"
        ["NU"]="${NU}"
        ["NC"]="${NC}"
    )
    DC+=( # Dialog positioning adjustment values
        ["WindowColsAdjust"]=6
        ["WindowRowsAdjust"]=5
        ["TextColsAdjust"]=4
        ["TextRowsAdjust"]=7
    )

    local -a VarList
    readarray -t VarList < <(run_script 'env_var_list' "${ColorFile}")
    for VarName in "${VarList[@]-}"; do
        DC["${VarName}"]="$(run_script 'env_get' "${VarName}" "${ColorFile}" | envsubst "${ColorVars}")"
    done
    DC["ThemeName"]="${ThemeName}"
    DIALOGOPTS="--colors  --cr-wrap --no-collapse --backtitle ${DC[BackTitle]}${BACKTITLE}"

    local LineCharacters, Scrollbar, Shadow
    LineCharacters="$(run_script 'env_get' "LineCharacters" "${MENU_INI_FILE}")"
    Scrollbar="$(run_script 'env_get' "Scrollbar" "${MENU_INI_FILE}")"
    Shadow="$(run_script 'env_get' "Shadow" "${MENU_INI_FILE}")"

    if [[ ${LineCharacters^^} =~ YES|TRUE ]]; then
        DIALOGOPTS+=" --lines"
    else
        DIALOGOPTS+=" --no-lines"
    fi
    if [[ ${Scrollbar^^} =~ YES|TRUE ]]; then
        DIALOGOPTS+=" --scrollbar"
    else
        DIALOGOPTS+=" --no-scrollbar"
    fi
    if [[ ${Shadow^^} =~ YES|TRUE ]]; then
        DIALOGOPTS+=" --shadow"
    else
        DIALOGOPTS+=" --no-shadow"
    fi
}

test_apply_theme() {
    warn "CI does not test apply_theme."
}
