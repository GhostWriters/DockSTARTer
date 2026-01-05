#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'
 
config_show() {
    local -a Keys=(
        "ConfigFolder"
        "ComposeFolder"
        "PackageManager"
        "Theme"
        "Borders"
        "LineCharacters"
        "Scrollbar"
        "Shadow"
    )

    local -A DisplayNames=(
        ["ConfigFolder"]="Config Folder"
        ["ComposeFolder"]="Compose Folder"
        ["PackageManager"]="Package Manager"
        ["Theme"]="Theme"
        ["Borders"]="Borders"
        ["LineCharacters"]="Line Characters"
        ["Scrollbar"]="Scrollbar"
        ["Shadow"]="Shadow"
    )

    local -a TableArray=()
    for Key in "${Keys[@]}"; do
        local Value
        Value="$(run_script 'config_get' "${Key}")"
        
        local ExpandedValue=""
        if [[ ${Key} == "ConfigFolder" || ${Key} == "ComposeFolder" ]]; then
            ExpandedValue="$(
                run_script 'expand_vars_using_varfile' "${Value}" "${Key}" "${APPLICATION_INI_FILE}" \
                HOME "${DETECTED_HOMEDIR}" \
                ScriptFolder "${SCRIPTPATH}" \
                XDG_CONFIG_HOME "${XDG_CONFIG_HOME}"
            )"
        fi
        
        local ValueColor="${C["Var"]-}"
        if [[ ${Key} == "ConfigFolder" || ${Key} == "ComposeFolder" ]]; then
            ValueColor="${C["Folder"]-}"
        fi

        local DisplayValue="${ValueColor}${Value}${NC-}"
        local DisplayExpandedValue=""
        if [[ -n ${ExpandedValue} ]]; then
            DisplayExpandedValue="${ValueColor}${ExpandedValue}${NC-}"
        fi
        
        TableArray+=("${DisplayNames[${Key}]}" "${DisplayValue}" "${DisplayExpandedValue}")
    done
    
    echo "Configuration options stored in '${C["File"]}${APPLICATION_INI_FILE}${NC}':"
    table 3 \
        "${C["UsageCommand"]}Option${NC}" "${C["UsageCommand"]}Value${NC}" "${C["UsageCommand"]}Expanded Value${NC}" \
        "${TableArray[@]}"
}
 
test_config_show() {
    run_script 'config_show'
}
