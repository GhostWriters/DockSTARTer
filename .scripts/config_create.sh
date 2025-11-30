#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

config_create() {
    if [[ ! -f ${APPLICATION_INI_FILE} ]]; then
        unset 'PM'
        local OldIniFile="${SCRIPTPATH}/menu.ini"
        if [[ -f ${OldIniFile} ]]; then
            # Migrate from the old menu.ini file
            notice "Renaming '${C["File"]-}${OldIniFile}${NC-}' to '${C["File"]-}${APPLICATION_INI_FILE}${NC-}'."
            mv "${OldIniFile}" "${APPLICATION_INI_FILE}" ||
                fatal \
                    "Failed to rename old config file." \
                    "Failing command: ${C["FailingCommand"]}mv \"${OldIniFile}\" \"${APPLICATION_INI_FILE}\""

        else
            # Copy the default .ini file
            local DefaultIniFile="${DEFAULTS_FOLDER}/${APPLICATION_INI_NAME}"
            notice "Copying '${C["File"]-}${DefaultIniFile}${NC-}' to '${C["File"]-}${APPLICATION_INI_FILE}${NC-}'."
            cp "${DefaultIniFile}" "${APPLICATION_INI_FILE}" ||
                fatal \
                    "Failed to copy default config file." \
                    "Failing command: ${C["FailingCommand"]}cp \"${DefaultIniFile}\" \"${APPLICATION_INI_FILE}\""

        fi
    fi
}

test_config_create() {
    warn "CI does not test create_config."
}
