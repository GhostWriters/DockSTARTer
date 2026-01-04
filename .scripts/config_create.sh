#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

config_create() {
    if [[ -f ${APPLICATION_INI_FILE} ]]; then
        # Config file already exists, do nothing
        return
    fi
    unset 'PM'

    if [[ ! -d ${APPLICATION_INI_FOLDER} ]]; then
        notice "Creating '${C["Folder"]-}${APPLICATION_INI_FOLDER}${NC-}'."
        mkdir -p "${APPLICATION_INI_FOLDER}" ||
            fatal \
                "Failed to create config folder." \
                "Failing command: ${C["FailingCommand"]}mkdir -p \"${APPLICATION_INI_FOLDER}\""
        run_script 'set_permissions' "${APPLICATION_INI_FOLDER}"
    fi

    local ConfigFolder ComposeFolder
    if [[ -f ${SCRIPTPATH}/${APPLICATION_INI_NAME} || -f ${SCRIPTPATH}/menu.ini ]]; then
        # At least one legacy config file exists, migrate it
        for LegacyIniFile in "${SCRIPTPATH}/${APPLICATION_INI_NAME}" "${SCRIPTPATH}/menu.ini"; do
            if [[ -f ${LegacyIniFile} ]]; then
                notice "Renaming '${C["File"]-}${LegacyIniFile}${NC-}' to '${C["File"]-}${APPLICATION_INI_FILE}${NC-}'."
                mv "${LegacyIniFile}" "${APPLICATION_INI_FILE}" ||
                    fatal \
                        "Failed to rename old config file." \
                        "Failing command: ${C["FailingCommand"]}mv \"${LegacyIniFile}\" \"${APPLICATION_INI_FILE}\""
                break
            fi
        done
        run_script 'set_permissions' "${APPLICATION_INI_FILE}"
        if ! run_script 'env_var_exists' ConfigFolder "${APPLICATION_INI_FILE}"; then
            ConfigFolder="$(run_script 'config_get' ConfigFolder "${DEFAULT_INI_FILE}")"
            run_script 'config_set' ConfigFolder "${ConfigFolder}"
        else
            ConfigFolder="$(run_script 'config_get' ConfigFolder)"
        fi
        if ! run_script 'env_var_exists' ComposeFolder "${APPLICATION_INI_FILE}"; then
            local LegacyComposeFolder="${SCRIPTPATH}/compose"
            shopt -s nullglob
            local LegacyComposeFiles=("${LegacyComposeFolder}/env_files/{emv_files,.env,.env.app.*,docker-compose.*}")
            shopt -u nullglob
            if [[ ${#LegacyComposeFiles[@]} -gt 0 ]]; then
                # The legacy compose folder location was being used, keep it
                ComposeFolder="${LegacyComposeFolder}"
            else
                ComposeFolder="$(run_script 'config_get' ComposeFolder "${DEFAULT_INI_FILE}")"
            fi
            run_script 'config_set' ComposeFolder "${ComposeFolder}"
        else
            ComposeFolder="$(run_script 'config_get' ComposeFolder)"
        fi
    fi

    if [[ ! -f ${APPLICATION_INI_FILE} ]]; then
        # Copy the default .ini file
        notice "Copying '${C["File"]-}${DEFAULT_INI_FILE}${NC-}' to '${C["File"]-}${APPLICATION_INI_FILE}${NC-}'."
        cp "${DEFAULT_INI_FILE}" "${APPLICATION_INI_FILE}" ||
            fatal \
                "Failed to copy default config file." \
                "Failing command: ${C["FailingCommand"]}cp \"${DEFAULT_INI_FILE}\" \"${APPLICATION_INI_FILE}\""
        ConfigFolder="$(run_script 'config_get' ConfigFolder)"
        ComposeFolder="$(run_script 'config_get' ComposeFolder)"
    fi
    local -a ExpandVarList=(
        ScriptFolder "${SCRIPTPATH}"
        XDG_CONFIG_HOME "${XDG_CONFIG_HOME}"
        HOME "${DETECTED_HOMEDIR}"
    )
    local ExpandedConfigFolder ExpandedComposeFolder
    ExpandedConfigFolder="$(expand_vars "${ConfigFolder}" "${ExpandVarList[@]}")"
    ExpandVarList=(
        DOCKER_CONFIG_FOLDER "${ExpandedConfigFolder}"
        "${ExpandVarList[@]}"
    )
    ExpandedComposeFolder="$(expand_vars "${ComposeFolder}" "${ExpandVarList[@]}")"
    notice \
        "Config folder location set to '${C["Folder"]-}${ConfigFolder}${NC-}'" \
        "   ('${C["Folder"]-}${ExpandedConfigFolder}${NC-}')" \
        "Compose folder location set to '${C["Folder"]-}${ComposeFolder}${NC-}'" \
        "   ('${C["Folder"]-}${ExpandedComposeFolder}${NC-}')"
}

test_config_create() {
    warn "CI does not test create_config."
}
