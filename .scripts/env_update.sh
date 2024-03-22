#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

env_update() {
    run_script 'env_backup'
    run_script 'override_backup'

    info "Replacing current .env file with latest template."
    local MKTEMP_ENV_CURRENT
    MKTEMP_ENV_CURRENT=$(mktemp) || fatal "Failed to create temporary current .env file.\nFailing command: ${F[C]}mktemp"
    sort "${COMPOSE_ENV}" > "${MKTEMP_ENV_CURRENT}" || fatal "Failed to sort to new file.\nFailing command: ${F[C]}sort \"${COMPOSE_ENV}\" > \"${MKTEMP_ENV_CURRENT}\""
    local ARRAY_ENV_CURRENT=()
    mapfile -t ARRAY_ENV_CURRENT < <(grep -v '^#' "${MKTEMP_ENV_CURRENT}" | grep '=')
    local MKTEMP_ENV_UPDATED
    MKTEMP_ENV_UPDATED=$(mktemp) || fatal "Failed to create temporary update .env file.\nFailing command: ${F[C]}mktemp"
    cp "${COMPOSE_ENV}.example" "${MKTEMP_ENV_UPDATED}" || fatal "Failed to copy file.\nFailing command: ${F[C]}cp \"${COMPOSE_ENV}.example\" \"${MKTEMP_ENV_UPDATED}\""

    info "Merging current values into updated .env file."
    local BUILTIN_APPS=()
    local ENABLED_LINES=()
    local INSTALLED_APPS=()
    local ENABLED_APPS=()
    local APPTEMPLATESFOLDER="${SCRIPTPATH}/compose/.apps"
    mapfile -t BUILTIN_APPS < <(ls -1d "${APPTEMPLATESFOLDER}"/* | xargs -l basename)
    mapfile -t ENABLED_LINES < <(grep --color=never -P '^[A-Z0-9]\w+_ENABLED=' "${MKTEMP_ENV_CURRENT}")
    for line in "${ENABLED_LINES[@]}"; do
        local VAR=${line%%=*}
        local APPNAME=${VAR%%_*}
        if inArray "${APPNAME}" "${BUILTIN_APPS[@]^^}"; then
            INSTALLED_APPS+=("${APPNAME}")
            if [ "$(run_script 'env_get' "${VAR}" "${MKTEMP_ENV_CURRENT}")" = 'true' ]; then
                ENABLED_APPS+=("${APPNAME}")
            fi
        fi
    done

    while [[ -n "${ARRAY_ENV_CURRENT[*]}" ]]; do
        local ENV_USER_DEFINED_LINES=()
        local ENV_BUILTIN_LINES=()
        local APPNAME
        local LAST_APPNAME
        local -a APP_LABEL_LIST
        for index in "${!ARRAY_ENV_CURRENT[@]}"; do
            local line="${ARRAY_ENV_CURRENT[$index]}"
            local SET_VAR=${line%%=*}
            APPNAME=${SET_VAR%%_*}
            if [ "${APPNAME}" != "${LAST_APPNAME-}" ]; then
                break
            fi
            if grep -q -P "^${SET_VAR}=" "${MKTEMP_ENV_UPDATED}"; then
                # Variable already exists
                local SET_VAL
                SET_VAL=$(run_script 'env_get' "${SET_VAR}" "${MKTEMP_ENV_CURRENT}")
                run_script 'env_set' "${SET_VAR}" "${SET_VAL}" "${MKTEMP_ENV_UPDATED}"
            else
                # Variable does not already exist
                if [[ -z "${APP_LABEL_LIST[*]}" ]]; then
                    if inArray "${APPNAME}" "${INSTALLED_APPS[@]}"; then
                        local APPTEMPLATE="${APPTEMPLATESFOLDER}/${APPNAME,,}/${APPNAME,,}.labels.yml"
                        mapfile -t APP_LABEL_LIST < <(grep --color=never -Po "\scom\.dockstarter\.appvars\.\K[\w]+" "${APPTEMPLATE}" ||true)
                        APP_LABEL_LIST=("${APP_LABEL_LIST[@]^^}")
                    fi
                fi
                if inArray "${SET_VAR}" "${APP_LABEL_LIST[@]}"; then
                    # Variable is built in
                    ENV_BUILTIN_LINES+=("${line}")
                else
                    # Variable is user defined
                    ENV_USER_DEFINED_LINES+=("${line}")
                fi
            fi
            unset 'ARRAY_ENV_CURRENT["$index"]'
        done
        if [[ -n "${ENV_BUILTIN_LINES[*]}" ]]; then
            # Add all built in variables for app
            echo "#" >> "${MKTEMP_ENV_UPDATED}" || error "# could not be written to ${MKTEMP_ENV_UPDATED}"
            echo "# ${LAST_APPNAME}" >> "${MKTEMP_ENV_UPDATED}" || error "# ${LAST_APPNAME} could not be written to ${MKTEMP_ENV_UPDATED}"
            echo "#" >> "${MKTEMP_ENV_UPDATED}" || error "# could not be written to ${MKTEMP_ENV_UPDATED}"
            for line in "${ENV_BUILTIN_LINES[@]}"; do
                local SET_VAR
                local SET_VAL
                SET_VAR=${line%%=*}
                SET_VAL=$(run_script 'env_get' "${SET_VAR}" "${MKTEMP_ENV_CURRENT}")
                echo "${line}" >> "${MKTEMP_ENV_UPDATED}" || error "${line} could not be written to ${MKTEMP_ENV_UPDATED}"
                run_script 'env_set' "${SET_VAR}" "${SET_VAL}" "${MKTEMP_ENV_UPDATED}"
            done
        fi
        if [[ -n "${ENV_USER_DEFINED_LINES[*]}" ]]; then
            # Add all user defined variables for app
            echo "#" >> "${MKTEMP_ENV_UPDATED}" || error "# could not be written to ${MKTEMP_ENV_UPDATED}"
            echo "# ${LAST_APPNAME} (User Defined)" >> "${MKTEMP_ENV_UPDATED}" || error "# ${LAST_APPNAME} (User Defined) could not be written to ${MKTEMP_ENV_UPDATED}"
            echo "#" >> "${MKTEMP_ENV_UPDATED}" || error "# could not be written to ${MKTEMP_ENV_UPDATED}"
            for line in "${ENV_USER_DEFINED_LINES[@]}"; do
                local SET_VAR
                local SET_VAL
                SET_VAR=${line%%=*}
                SET_VAL=$(run_script 'env_get' "${SET_VAR}" "${MKTEMP_ENV_CURRENT}")
                echo "${line}" >> "${MKTEMP_ENV_UPDATED}" || error "${line} could not be written to ${MKTEMP_ENV_UPDATED}"
                run_script 'env_set' "${SET_VAR}" "${SET_VAL}" "${MKTEMP_ENV_UPDATED}"
            done
        fi
        APP_LABEL_LIST=()
        LAST_APPNAME=${APPNAME}
        ARRAY_ENV_CURRENT=("${ARRAY_ENV_CURRENT[@]}")
    done
    rm -f "${MKTEMP_ENV_CURRENT}" || warn "Failed to remove temporary .env update file.\nFailing command: ${F[C]}rm -f \"${MKTEMP_ENV_CURRENT}\""
    cp -f "${MKTEMP_ENV_UPDATED}" "${COMPOSE_ENV}" || fatal "Failed to copy file.\nFailing command: ${F[C]}cp -f \"${MKTEMP_ENV_UPDATED}\" \"${COMPOSE_ENV}\""
    rm -f "${MKTEMP_ENV_UPDATED}" || warn "Failed to remove temporary .env update file.\nFailing command: ${F[C]}rm -f \"${MKTEMP_ENV_UPDATED}\""
    run_script 'set_permissions' "${COMPOSE_ENV}"
    run_script 'env_sanitize'
    info "Environment file update complete."
}

inArray() {
    # Check if $1 is in array $2
    local e match="$1"
    shift
    for e; do [[ "$e" == "$match" ]] && return 0; done
    return 1
}

test_env_update() {
    run_script 'env_update'
}
