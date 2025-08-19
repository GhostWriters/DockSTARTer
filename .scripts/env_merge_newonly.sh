#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

env_merge_newonly() {
    # env_merge_newonly "MergeToFile" "MergeFromFile"
    #
    # Merges all new variables from "MergeFromFile" to "MergeToFile".
    # Skips all variables that already exist in "MergeToFile"
    local MergeToFile=${1-}
    local MergeFromFile=${2-}

    # If "MergeToFile" doesn't exists, create it
    if [[ ! -f ${MergeToFile} ]]; then
        touch "${MergeToFile}"
    fi

    # If "MergeFromFile" doesn't exists, give a warning
    if [[ ! -f ${MergeFromFile} ]]; then
        warn "File '${C["File"]}${MergeFromFile}${NC}' does not exist."
    else
        local MergeFromLines=()
        # Read all variable lines into an array, stripping whitespace before and after the variable name
        readarray -t MergeFromLines < <(sed -n -E "s/^\s*(\w+)\s*=/\1=/p" "${MergeFromFile}" 2> /dev/null || true)
        if [[ ${#MergeFromLines[@]} != 0 ]]; then
            for index in "${!MergeFromLines[@]}"; do
                local line="${MergeFromLines[index]}" 2> /dev/null
                local VarName="${line%%=*}" 2> /dev/null
                if grep -q -P "^\s*${VarName}\s*=\K.*" "${MergeToFile}" 2> /dev/null; then
                    # Variable is already in file, skip it
                    unset 'MergeFromLines[$index]' 2> /dev/null
                fi
            done
            declare -gx PROCESS_APPVARS_CREATE_ALL=1
            declare -gx PROCESS_ENV_UPDATE=1
            declare -gx PROCESS_YML_MERGE=1
        fi
        if [[ ${#MergeFromLines[@]} != 0 ]]; then
            notice "Adding variables to ${C["File"]}${MergeToFile}${NC}:"
            echo >> "${MergeToFile}" || fatal "Failed to write to '${C["File"]}${MergeToFile}${NC}'.\nFailing command: ${C["FailingCommand"]}echo >> \"${MergeToFile}\"${NC}"
            for index in "${!MergeFromLines[@]}"; do
                local line="${MergeFromLines[index]}" 2> /dev/null
                notice "   ${C["Var"]}${line}${NC}"
                env -i line="${line}" MergeToFile="${MergeToFile}" \
                    printf '%s\n' "${line}" >> "${MergeToFile}" 2> /dev/null || fatal "Failed to add variable to '${C["File"]}${MergeToFile}${NC}'\nFailing command: ${C["FailingCommand"]}printf '%s\n' \"${line}\" >> \"${MergeToFile}\""
            done
            declare -gx PROCESS_APPVARS_CREATE_ALL=1
            declare -gx PROCESS_ENV_UPDATE=1
            declare -gx PROCESS_YML_MERGE=1
        fi
    fi
}

test_env_merge_newonly() {
    #run_script 'env_merge_newonly'
    warn "CI does not test env_merge_newonly."
}
