#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

override_var_rename() {
    local FromVar=${1-}
    local ToVar=${2-}

    if [[ ! -f ${COMPOSE_OVERRIDE} ]]; then
        # No override file exists, do nothing
        return
    fi
    if run_script 'override_var_exists' "${FromVar}"; then
        notice "Renaming variable in ${C["File"]}${COMPOSE_OVERRIDE}${NC}:"
        notice "   ${C["Var"]}${FromVar}${NC} to ${C["Var"]}${ToVar}${NC}"
        # Replace $FromVar or ${FromVar followed by a word break to $ToVar or ${ToVar
        sed -i -E "s/([$]\{?)${FromVar}\b/\1${ToVar}/g" "${COMPOSE_OVERRIDE}" ||
            fatal "Failed to rename variable in override file.\nFailing command: ${C["FailingCommand"]} sed -i -E \"s/([$]\\{?)${FromVar}\\\\b/\\\\1${ToVar}/g\" \"${COMPOSE_OVERRIDE}\""
        declare -gx PROCESS_YML_MERGE=1

    fi
}

test_override_var_rename() {
    warn "CI does not test override_var_rename."
}
