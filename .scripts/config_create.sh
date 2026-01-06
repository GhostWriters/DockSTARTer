#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

config_create() {

    if [[ ! -d ${APPLICATION_INI_FOLDER} ]]; then
        notice "Creating '${C["Folder"]-}${APPLICATION_INI_FOLDER}${NC-}'."
        mkdir -p "${APPLICATION_INI_FOLDER}" ||
            fatal \
                "Failed to create config folder." \
                "Failing command: ${C["FailingCommand"]}mkdir -p \"${APPLICATION_INI_FOLDER}\""
        run_script 'set_permissions' "${APPLICATION_INI_FOLDER}"
    fi

    local ConfigFolder ComposeFolder
    local ShowNotice=false
    local FreshInstall=false

    # Handle legacy config files
    if [[ -f ${SCRIPTPATH}/${APPLICATION_INI_NAME} || -f ${SCRIPTPATH}/menu.ini ]]; then
        for LegacyIniFile in "${SCRIPTPATH}/${APPLICATION_INI_NAME}" "${SCRIPTPATH}/menu.ini"; do
            if [[ -f ${LegacyIniFile} ]]; then
                if [[ ${LegacyIniFile} == "${APPLICATION_INI_FILE}" ]]; then
                    continue
                fi
                notice "Renaming '${C["File"]-}${LegacyIniFile}${NC-}' to '${C["File"]-}${APPLICATION_INI_FILE}${NC-}'."
                mv "${LegacyIniFile}" "${APPLICATION_INI_FILE}" ||
                    fatal \
                        "Failed to rename old config file." \
                        "Failing command: ${C["FailingCommand"]}mv \"${LegacyIniFile}\" \"${APPLICATION_INI_FILE}\""
                break
            fi
        done
        run_script 'set_permissions' "${APPLICATION_INI_FILE}"
    fi

    # Handle missing config file
    if [[ ! -f ${APPLICATION_INI_FILE} ]]; then
        # Copy the default .ini file
        notice "Copying '${C["File"]-}${DEFAULT_INI_FILE}${NC-}' to '${C["File"]-}${APPLICATION_INI_FILE}${NC-}'."
        cp "${DEFAULT_INI_FILE}" "${APPLICATION_INI_FILE}" ||
            fatal \
                "Failed to copy default config file." \
                "Failing command: ${C["FailingCommand"]}cp \"${DEFAULT_INI_FILE}\" \"${APPLICATION_INI_FILE}\""
        ShowNotice=true
        FreshInstall=true
    fi

    # Ensure ConfigFolder is set
    if ! run_script 'env_var_exists' ConfigFolder "${APPLICATION_INI_FILE}"; then
        ConfigFolder="$(run_script 'config_get' ConfigFolder "${DEFAULT_INI_FILE}")"
        run_script 'config_set' ConfigFolder "${ConfigFolder}"
        ShowNotice=true
    else
        ConfigFolder="$(run_script 'config_get' ConfigFolder)"
    fi

    local -a ExpandVarList=(
        ScriptFolder "${SCRIPTPATH}"
        XDG_CONFIG_HOME "${XDG_CONFIG_HOME}"
        HOME "${DETECTED_HOMEDIR}"
    )
    local ExpandedConfigFolder
    ExpandedConfigFolder="$(expand_vars "${ConfigFolder}" "${ExpandVarList[@]}")"
    ExpandVarList=(
        DOCKER_CONFIG_FOLDER "${ExpandedConfigFolder}"
        "${ExpandVarList[@]}"
    )

    # Ensure ComposeFolder is set
    if [[ ${FreshInstall} == true ]] || ! run_script 'env_var_exists' ComposeFolder "${APPLICATION_INI_FILE}"; then
        # shellcheck disable=SC2016 # Expressions don't expand in single quotes, use double quotes for that.
        local LegacyComposeFolder='${ScriptFolder}/compose'
        local ExpandedLegacyComposeFolder
        ExpandedLegacyComposeFolder="$(expand_vars "${LegacyComposeFolder}" "${ExpandVarList[@]}")"

        local LegacyHasFiles=false
        if [[ -d ${ExpandedLegacyComposeFolder} ]] && ! folder_is_empty "${ExpandedLegacyComposeFolder}"; then
            LegacyHasFiles=true
        fi

        local DefaultComposeFolder
        DefaultComposeFolder="$(run_script 'config_get' ComposeFolder "${DEFAULT_INI_FILE}")"
        local ExpandedDefaultComposeFolder
        ExpandedDefaultComposeFolder="$(expand_vars "${DefaultComposeFolder}" "${ExpandVarList[@]}")"

        local DefaultHasFiles=false
        if [[ -d ${ExpandedDefaultComposeFolder} ]] && ! folder_is_empty "${ExpandedDefaultComposeFolder}"; then
            DefaultHasFiles=true
        fi

        if [[ ${LegacyHasFiles} == true ]] && [[ ${DefaultHasFiles} == true ]] && [[ ${ExpandedLegacyComposeFolder} != "${ExpandedDefaultComposeFolder}" ]]; then
            # Both the legacy and default compose folders have files in them, ask which to use
            local PromptMessage="Existing docker compose folders found in multiple locations.\n   Legacy:  '${C["Folder"]-}${ExpandedLegacyComposeFolder}${NC-}'\n   Default: '${C["Folder"]-}${ExpandedDefaultComposeFolder}${NC-}'\n\nWould you like to use the Legacy location?"
            if run_script 'question_prompt' "Y" "${PromptMessage}" "Multiple Compose Folders Detected" "" "Legacy" "Default"; then
                notice \
                    "Chose the Legacy compose folder location:" \
                    "   '${C["Folder"]-}${ExpandedLegacyComposeFolder}${NC-}'"
                ComposeFolder="${LegacyComposeFolder}"
            else
                notice \
                    "Chose the Default compose folder location:" \
                    "   '${C["Folder"]-}${ExpandedDefaultComposeFolder}${NC-}'"
                ComposeFolder="${DefaultComposeFolder}"
            fi
        elif [[ ${LegacyHasFiles} == true ]]; then
            # The legacy compose folder location was being used, keep it
            ComposeFolder="${LegacyComposeFolder}"
        else
            ComposeFolder="${DefaultComposeFolder}"
        fi
        run_script 'config_set' ComposeFolder "${ComposeFolder}"
        ShowNotice=true
    else
        ComposeFolder="$(run_script 'config_get' ComposeFolder)"
    fi

    if [[ ${ShowNotice} == true ]]; then
        notice ""
        notice "$(run_script 'config_show')"
        notice ""
    fi
}

test_config_create() {
    warn "CI does not test create_config."
}
