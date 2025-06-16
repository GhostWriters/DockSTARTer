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

        local -a CurrentGlobalVars DefaultGlobalVars GlobalVarsToRemove GlobalLinesToRemoveArray
        local -a CurrentAppEnvVars DefaultAppEnvVars AppEnvVarsToRemove AppEnvLinesToRemoveArray
        local GlobalLinesToRemove AppEnvLinesToRemove
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
            readarray -t GlobalLinesToRemoveArray <<< "$(grep -P "^\s*${GlobalVarsRegex}\s*=" "${COMPOSE_ENV}" || true)"
            GlobalLinesToRemove="$(printf '   %s\n' "${GlobalLinesToRemoveArray[@]-}")"
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
            readarray -t AppEnvLinesToRemoveArray <<< "$(grep -P "^\s*${AppEnvVarsRegex}\s*=" "${AppEnvFile}" || true)"
            AppEnvLinesToRemove="$(printf '   %s\n' "${AppEnvLinesToRemoveArray[@]-}")"
        fi

        if [[ -z ${GlobalVarsToRemove[*]-} && -z ${AppEnvVarsToRemove[*]-} ]]; then
            if use_dialog_box; then
                dialog_error "{Title}" "${APPNAME} has no variables to remove."
            else
                warn "Application ${AppName} has no variables to remove."
            fi
            continue
        fi

        local QUESTION
        QUESTION="$(
            cat << EOF
Would you like to purge these settings for ${AppName}?

${COMPOSE_ENV}:
${GlobalLinesToRemove-}

${AppEnvFile}:
${AppEnvLinesToRemove-}
EOF
        )"
        if [[ ${CI-} == true ]] || run_script 'question_prompt' Y "${QUESTION}\n" "${Title}" "${FORCE:+Y}"; then
            info "Purging ${AppName} .env variables."

            if [[ -n ${GlobalVarsToRemove[*]-} ]]; then
                # Remove variables from global .env file
                notice "Removing variables from ${COMPOSE_ENV}:"
                for line in "${GlobalLinesToRemoveArray[@]}"; do
                    notice "   $line"
                done
                sed -i -E "/^\s*(${GlobalVarsRegex})\s*=/d" "${COMPOSE_ENV}" ||
                    fatal "Failed to purge ${AppName} variables.\nFailing command: ${F[C]}sed -i -E \"/^\\\*(${GlobalVarsRegex})\\\*/d\" \"${COMPOSE_ENV}\""
            fi
            if [[ -n ${AppEnvVarsToRemove[*]-} ]]; then
                # Remove variables from file
                notice "Removing variables from ${AppEnvFile}:"
                for line in "${AppEnvLinesToRemoveArray[@]}"; do
                    notice "   $line"
                done
                sed -i -E "/^\s*(${AppEnvVarsRegex})\s*=/d" "${AppEnvFile}" ||
                    fatal "Failed to purge ${AppName} variables.\nFailing command: ${F[C]}sed -i -E \"/^\\\*(${AppEnvVarsRegex})\\\*/d\" \"${AppEnvFile}\""
            fi
        else
            info "Keeping ${AppName} .env variables."
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
