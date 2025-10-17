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
        touchfile "${MergeToFile}"
    fi

    # If "MergeFromFile" doesn't exists, give a warning
    if [[ ! -f ${MergeFromFile} ]]; then
        warn "File '${C["File"]}${MergeFromFile}${NC}' does not exist."
    else
        local -a MergeFromVars MergeToVars VarsToAdd
        readarray -t MergeFromVars < <(run_script 'env_var_list' "${MergeFromFile}")
        readarray -t MergeToVars < <(run_script 'env_var_list' "${MergeToFile}")
        readarray -t VarsToAdd < <(comm -23 <(printf '%s\n' "${MergeFromVars[@]}" | sort) <(printf '%s\n' "${MergeToVars[@]}" | sort))
        if [[ -n ${VarsToAdd[*]-} ]]; then
            local old_IFS="${IFS}"
            IFS='|'
            local VarsToAddRegex="${VarsToAdd[*]}"
            IFS="${old_IFS}"
            local MergeLines
            readarray -t MergeLines < <(
                run_script 'env_get_line_regex' "${VarsToAddRegex}" "${MergeFromFile}"
            )
            notice \
                "Adding variables to ${C["File"]}${MergeToFile}${NC}:\n" \
                "$(printf "   ${C[Var]}%s${NC}\n" "${MergeLines[@]}")"
            {
                printf '\n'
                printf '%s\n' "${MergeLines[@]}"
            } >> "${MergeToFile}" || fatal "Failed to add variables to '${C["File"]}${MergeToFile}${NC}"
        fi
    fi
}

test_env_merge_newonly() {
    #run_script 'env_merge_newonly'
    warn "CI does not test env_merge_newonly."
}
