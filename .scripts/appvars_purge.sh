#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

appvars_purge() {
    local Title="Purge Variables"
    local AppList
    AppList="$(xargs -n 1 <<< "$*")"
    for APPNAME in ${AppList^^}; do
        local AppName
        AppName=$(run_script 'app_nicename' "${APPNAME}")

        local AppEnvFile
        AppEnvFile="$(run_script 'app_env_file' "${APPNAME}")"

        local -a CurrentGlobalVars DefaultGlobalVars GlobalVarsToRemove GlobalLinesToRemove
        local -a CurrentAppEnvVars DefaultAppEnvVars AppEnvVarsToRemove AppEnvLinesToRemove
        local GlobalVarsRegex AppEnvVarsRegex

        readarray -t CurrentGlobalVars <<< "$(run_script 'appvars_list' "${APPNAME}")"
        if [[ -n ${CurrentGlobalVars-} ]]; then
            readarray -t DefaultGlobalVars <<< "$(run_script 'env_list_app_global_defaults' "${APPNAME}")"
            # Get the list of current variables also in the default list
            readarray -t GlobalVarsToRemove <<< "$(
                printf '%s\n' "${CurrentGlobalVars[@]-}" "${DefaultGlobalVars[@]-}" |
                    tr ' ' '\n' | sort | uniq -d || true
            )"
            {
                IFS='|'
                GlobalVarsRegex="${GlobalVarsToRemove[*]}"
            }
            readarray -t GlobalLinesToRemove <<< "$(grep -P "^\s*${GlobalVarsRegex}\s*=" "${COMPOSE_ENV}" || true)"
        fi

        readarray -t CurrentAppEnvVars <<< "$(run_script 'appvars_list' "${APPNAME}:")"
        if [[ -n ${CurrentAppEnvVars-} ]]; then
            readarray -t DefaultAppEnvVars <<< "$(run_script 'env_list_app_env_defaults' "${APPNAME}")"
            # Get the list of current variables also in the default list
            readarray -t AppEnvVarsToRemove <<< "$(
                printf '%s\n' "${CurrentAppEnvVars[@]-}" "${DefaultAppEnvVars[@]-}" |
                    tr ' ' '\n' | sort | uniq -d || true
            )"
            {
                IFS='|'
                AppEnvVarsRegex="${AppEnvVarsToRemove[*]}"
            }
            readarray -t AppEnvLinesToRemove <<< "$(grep -P "^\s*${AppEnvVarsRegex}\s*=" "${AppEnvFile}" || true)"
        fi

        if [[ -z ${GlobalVarsToRemove[*]-} && -z ${AppEnvVarsToRemove[*]-} ]]; then
            local WarningText="'${DC["Highlight"]}${C["App"]}${APPNAME}${NC}${DC[NC]}' has no variables to remove."
            if use_dialog_box; then
                dialog_warning "{Title}" "${WarningText}"
                warn "${WarningText}" &> /dev/null
            else
                warn "${WarningText}"
            fi
            continue
        fi

        local Indent='   '
        local Question
        Question="Would you like to purge these settings for '${DC["Highlight"]}${C["App"]}${AppName}${NC}${DC[NC]}'?\n"
        if [[ -n ${GlobalLinesToRemove[*]-} ]]; then
            Question+="${Indent}${DC["Highlight"]}${C["Folder"]}${COMPOSE_ENV}${NC}${DC[NC]}:\n"
            for line in "${GlobalLinesToRemove[@]}"; do
                Question+="${Indent}${Indent}${C["Var"]}${line}${NC}\n"
            done
        fi
        if [[ -n ${AppEnvLinesToRemove[*]-} ]]; then
            Question+="${Indent}${DC["Highlight"]}${C["Folder"]}${AppEnvFile}${NC}${DC[NC]}:\n"
            for line in "${AppEnvLinesToRemove[@]}"; do
                Question+="${Indent}${Indent}${C["Var"]}${line}${NC}\n"
            done
        fi
        if [[ ${CI-} == true ]] || run_script 'question_prompt' Y "${Question}" "${Title}" "${FORCE:+Y}"; then
            info "Purging '${C["App"]}${AppName}${NC}' variables."

            if [[ -n ${GlobalVarsToRemove[*]-} ]]; then
                # Remove variables from global .env file
                notice \
                    "Removing variables from ${C["File"]}${COMPOSE_ENV}${NC}:\n" \
                    "$(printf "${Indent}${C[Var]}%s${NC}\n" "${GlobalLinesToRemove[@]}")"
                sed -i -E "/^\s*(${GlobalVarsRegex})\s*=/d" "${COMPOSE_ENV}" ||
                    fatal "Failed to purge '${C["App"]}${AppName}${NC}' variables.\nFailing command: ${C["FailingCommand"]}sed -i -E \"/^\\\*(${GlobalVarsRegex})\\\*/d\" \"${COMPOSE_ENV}\""
            fi
            if [[ -n ${AppEnvVarsToRemove[*]-} ]]; then
                # Remove variables from file
                notice \
                    "Removing variables from ${C["File"]}${AppEnvFile}${NC}:\n" \
                    "$(printf "${Indent}${C[Var]}%s${NC}\n" "${AppEnvLinesToRemove[@]-}")"
                sed -i -E "/^\s*(${AppEnvVarsRegex})\s*=/d" "${AppEnvFile}" ||
                    fatal "Failed to purge '${C["App"]}${AppName}${NC}' variables.\nFailing command: ${C["FailingCommand"]}sed -i -E \"/^\\\*(${AppEnvVarsRegex})\\\*/d\" \"${AppEnvFile}\""
            fi
            declare -gx PROCESS_APPVARS_CREATE_ALL=1
            declare -gx PROCESS_ENV_UPDATE=1
            declare -gx PROCESS_YML_MERGE=1
        else
            info "Keeping '${C["App"]}${AppName}${NC}' variables."
        fi
    done
}

test_appvars_purge() {
    run_script 'appvars_purge' WATCHTOWER
    run_script 'env_update'
    echo "${COMPOSE_ENV}:"
    cat "${COMPOSE_ENV}"
    local EnvFile
    EnvFile="$(run_script 'app_env_file' "watchtower")"
    echo "${EnvFile}:"
    cat "${EnvFile}"
}
