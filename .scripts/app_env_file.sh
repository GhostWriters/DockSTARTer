#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_env_file() {
    local -l appname=${1:-}

    local AppEnvFilename=".env.app.${appname}"
    local OldAppEnvFilename="${appname}.env"
    local AppEnvFile="${COMPOSE_FOLDER}/${AppEnvFilename}"
    local OldAppEnvFile="${APP_ENV_FOLDER}/${OldAppEnvFilename}"

    if [[ ! -f ${AppEnvFile} && -f ${OldAppEnvFile} ]]; then
        # Migrate from the old env_files/appname.env files to .env.app.appname
        notice "Renaming '${C["File"]}${OldAppEnvFile}${NC}' to '${C["File"]}${AppEnvFile}${NC}'"
        mv "${OldAppEnvFile}" "${AppEnvFile}" ||
            fatal "Failed to rename file.\nFailing command: ${C["FailingCommand"]}mv \"${OldAppEnvFile}\" \"${AppEnvFile}\""
        local SearchString="${APP_ENV_FOLDER_NAME}/${OldAppEnvFilename}"
        if [[ -f ${COMPOSE_OVERRIDE} ]] && grep -q -F "${SearchString}" "${COMPOSE_OVERRIDE}"; then
            local ReplaceString="${AppEnvFilename}"
            # Replace all references to 'env_files/appname.env' with '.env.app.appname' in the override file
            notice "Replacing in '${C["File"]}${COMPOSE_OVERRIDE}${NC}':"
            notice "   '${C["Var"]}${SearchString}${NC}' with '${C["Var"]}${ReplaceString}${NC}'"
            # Escape . to [.] to use in sed
            SearchString="${SearchString//./[.]}"
            sed -i "s|${SearchString}|${ReplaceString}|g" "${COMPOSE_OVERRIDE}" ||
                fatal "Failed to edit override file.\nFailing command: ${C["FailingCommand"]}sed -i \"s|${SearchString}|${ReplaceString}|g\" \"${COMPOSE_OVERRIDE}\""
        fi
    fi
    echo "${AppEnvFile}"
}

test_app_env_file() {
    for AppName in watchtower radarr radarr__4k; do
        notice "[${AppName}] [$(run_script 'app_env_file' "${AppName}")]"
    done
}
