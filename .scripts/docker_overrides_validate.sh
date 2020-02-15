#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

docker_overrides_validate() {
    local PREVAL=${1:-N}
    local DOCKER_OVERRIDES_DIR
    DOCKER_OVERRIDES_DIR=$(run_script 'env_get' DOCKEROVERRIDESDIR)
    local VALIDATION_ERRORS=0

    info "Running Docker Overrides Validator"
    # Check for the directory and files should this be used from the command line
    if [[ ! -d ${DOCKER_OVERRIDES_DIR} ]]; then
        error "${DOCKER_OVERRIDES_DIR}/ does not exist. Create it and populate it with files to validate."
        return
    fi
    if [[ $(find "${DOCKER_OVERRIDES_DIR}"/* -type f -prune | wc -l) -eq 0 ]]; then
        error "No YML files found in ${DOCKER_OVERRIDES_DIR}/ to validate."
        return
    fi
    info "Validating YML files in ${DOCKER_OVERRIDES_DIR}/"
    shopt -s dotglob
    while IFS= read -r path; do
        if [[ -f ${path} ]]; then
            if yq-go v "${path}" > /dev/null 2>&1; then
                info "${path//${DOCKER_OVERRIDES_DIR}\//} valid!"
            else
                error "${path//${DOCKER_OVERRIDES_DIR}\//} is not valid yml and will not be included when generating. See errors below."
                yq-go v "${path}" || true
                VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
            fi
        fi
    done < <(find "${DOCKER_OVERRIDES_DIR}"/* -type f -prune)
    shopt -u dotglob

    # Output final status
    if [[ ${VALIDATION_ERRORS} -gt 0 ]]; then
        error "Validation errors were found. See errors above for more information."
        # Only return status code 1 if this is running as pre-validation
        if [[ ${PREVAL:-N} == "Y" ]]; then
            return 1
        fi
    else
        notice "Validation completed without errors!"
    fi
}

test_docker_overrides_validate() {
    run_script 'docker_overrides_validate'
}
