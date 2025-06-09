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
        warn "File ${MergeFromFile} does not exist."
    else
        local MergeFromLines=()
        # Read all variable lines into an array, stripping whitespace before and after the variable name
        readarray -t MergeFromLines < <(sed -n -E "s/^\s*(\w+)\s*=/\1=/p" "${MergeFromFile}" || true)
        if [[ -n ${MergeFromLines[*]-} ]]; then
            for index in "${!MergeFromLines[@]}"; do
                local line=${MergeFromLines[index]}
                local VarName="${line%%=*}"
                if grep -q -P "^\s*${VarName}\s*=\K.*" "${MergeToFile}"; then
                    # Variable is already in file, skip it
                    unset 'MergeFromLines[index]'
                fi
            done
        fi
        if [[ -n ${MergeFromLines[*]-} ]]; then
            notice "Adding variables to ${MergeToFile}:"
            for line in "${MergeFromLines[@]-}"; do
                notice "   $line"
            done
            echo >> "${MergeToFile}" || fatal "Failed to write to ${MergeToFile}.\nFailing command: echo >> \"${MergeToFile}\""
            printf '%s\n' "${MergeFromLines[@]}" >> "${MergeToFile}" || fatal "Failed to add variables to ${MergeToFile}"
        fi
    fi
}

test_env_merge_newonly() {
    #run_script 'env_merge_newonly'
    warn "CI does not test env_merge_newonly."
}
