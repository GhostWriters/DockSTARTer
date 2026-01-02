#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

config_create() {
    if [[ -f ${APPLICATION_INI_FILE} ]]; then
        # Config file already exists, do nothing
        return
    fi
    unset 'PM'
    if [[ -f ${SCRIPTPATH}/${APPLICATION_INI_NAME} || -f ${SCRIPTPATH}/menu.ini ]]; then
        # Migrate from the old .ini file locations
        for OldIniFile in "${SCRIPTPATH}/${APPLICATION_INI_NAME}" "${SCRIPTPATH}/menu.ini"; do
            if [[ -f ${OldIniFile} ]]; then
                notice "Renaming '${C["File"]-}${OldIniFile}${NC-}' to '${C["File"]-}${APPLICATION_INI_FILE}${NC-}'."
                mv "${OldIniFile}" "${APPLICATION_INI_FILE}" ||
                    fatal \
                        "Failed to rename old config file." \
                        "Failing command: ${C["FailingCommand"]}mv \"${OldIniFile}\" \"${APPLICATION_INI_FILE}\""
                break
            fi
        done
        run_script 'config_set' ConfigFolder "$(run_script 'config_get' ConfigFolder "${DEFAULT_INI_FILE}")"
        run_script 'config_set' ComposeFolder "${SCRIPTPATH}/${COMPOSE_FOLDER_NAME}"
    fi
    if [[ ! -f ${APPLICATION_INI_FILE} ]]; then
        # Copy the default .ini file
        notice "Copying '${C["File"]-}${DEFAULT_INI_FILE}${NC-}' to '${C["File"]-}${APPLICATION_INI_FILE}${NC-}'."
        cp "${DEFAULT_INI_FILE}" "${APPLICATION_INI_FILE}" ||
            fatal \
                "Failed to copy default config file." \
                "Failing command: ${C["FailingCommand"]}cp \"${DEFAULT_INI_FILE}\" \"${APPLICATION_INI_FILE}\""
    fi
}

test_config_create() {
    warn "CI does not test create_config."
}
