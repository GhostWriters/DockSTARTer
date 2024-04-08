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
    local INSTALLED_APPS=()
    #local ENABLED_APPS=()
    local APPTEMPLATESFOLDER="${SCRIPTPATH}/compose/.apps"

    # Create array of built in apps
    mapfile -t BUILTIN_APPS < <(find "${APPTEMPLATESFOLDER}" -maxdepth 1 -mindepth 1 -type d -exec basename {} \;)

    # Create array of installed apps
    {
        local ENABLED_LINES=()
        mapfile -t ENABLED_LINES < <(grep --color=never -P '^[A-Z0-9]\w+_ENABLED=' "${MKTEMP_ENV_CURRENT}")
        for line in "${ENABLED_LINES[@]}"; do
            local VAR=${line%%=*}
            local APPNAME=${VAR%%_*}
            # shellcheck disable=SC2199
            if [[ " ${BUILTIN_APPS[@]^^} " == *" ${APPNAME} "* ]]; then
                INSTALLED_APPS+=("${APPNAME}")
                #if [ "$(run_script 'env_get' "${VAR}" "${MKTEMP_ENV_CURRENT}")" = 'true' ]; then
                #    ENABLED_APPS+=("${APPNAME}")
                #fi
            fi
        done
    }

    # Process .env lines
    while [[ -n ${ARRAY_ENV_CURRENT[*]} ]]; do
        # Loop while there are lines in array
        local ENV_USER_DEFINED_LINES=()
        local ENV_BUILTIN_LINES=()
        local APP_LABEL_LIST=()

        local APPNAME
        local LAST_APPNAME

        for index in "${!ARRAY_ENV_CURRENT[@]}"; do
            # Process lines for one app
            local line="${ARRAY_ENV_CURRENT[$index]}"
            local SET_VAR=${line%%=*}
            APPNAME=${SET_VAR%%_*}
            if [ "${APPNAME}" != "${LAST_APPNAME-}" ]; then
                # Variable for another app, exit for loop
                break
            fi
            if grep -q -P "^${SET_VAR}=" "${MKTEMP_ENV_UPDATED}"; then
                # Variable already exists, update its value
                local SET_VAL
                SET_VAL=$(run_script 'env_get' "${SET_VAR}" "${MKTEMP_ENV_CURRENT}")
                run_script 'env_set' "${SET_VAR}" "${SET_VAL}" "${MKTEMP_ENV_UPDATED}"
            else
                # Variable does not already exist, add it to a list to process
                if [[ -z ${APP_LABEL_LIST[*]} ]]; then
                    # shellcheck disable=SC2199
                    if [[ " ${INSTALLED_APPS[@]} " == *" ${APPNAME} "* ]]; then
                        # Create array of labels for current app being processed
                        local APPTEMPLATE="${APPTEMPLATESFOLDER}/${APPNAME,,}/${APPNAME,,}.labels.yml"
                        mapfile -t APP_LABEL_LIST < <(grep --color=never -Po "\scom\.dockstarter\.appvars\.\K[\w]+" "${APPTEMPLATE}" || true)
                        APP_LABEL_LIST=("${APP_LABEL_LIST[@]^^}")
                    fi
                fi
                # shellcheck disable=SC2199
                if [[ " ${APP_LABEL_LIST[@]} " == *" ${SET_VAR} "* ]]; then
                    # Add line to the built in list
                    ENV_BUILTIN_LINES+=("${line}")
                else
                    # Add line to the user defined list
                    ENV_USER_DEFINED_LINES+=("${line}")
                fi
            fi
            # Remove processed line from array
            unset 'ARRAY_ENV_CURRENT[index]'
        done

        # Add the lines in the built in list and user defined list for last app being processed if they exist
        AddEnvSection "${MKTEMP_ENV_CURRENT}" "${MKTEMP_ENV_UPDATED}" "${LAST_APPNAME-}" "${ENV_BUILTIN_LINES[@]}"
        AddEnvSection "${MKTEMP_ENV_CURRENT}" "${MKTEMP_ENV_UPDATED}" "${LAST_APPNAME-} (User Defined)" "${ENV_USER_DEFINED_LINES[@]}"

        # Set last app worked on, remove all processed lines from array
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

AddEnvSection() { # OLD_ENVFILE, NEW_ENVFILE, HEADING, [lines]
    local OLD_ENVFILE=${1-}
    shift
    local NEW_ENVFILE=${1-}
    shift
    local HEADING=${1-}
    shift
    if [[ -n $* ]]; then
        if [[ -n ${HEADING} ]]; then
            printf -v HEADING '#\n# %s\n#\n' "${HEADING}"
            printf '%s' "${HEADING}" >> "${NEW_ENVFILE}" || error "${HEADING} could not be written to ${NEW_ENVFILE}"
        fi
        for line in "$@"; do
            local SET_VAR
            local SET_VAL
            SET_VAR=${line%%=*}
            SET_VAL=$(run_script 'env_get' "${SET_VAR}" "${OLD_ENVFILE}")
            run_script 'env_set' "${SET_VAR}" "${SET_VAL}" "${NEW_ENVFILE}"
        done
    fi
}

test_env_update() {
    run_script 'env_update'
}
