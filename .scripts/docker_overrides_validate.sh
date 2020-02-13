#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

docker_overrides_validate() {
    DOCKER_OVERRIDES_DIR="${DETECTED_HOMEDIR}/.config/docker_overrides"
    VALIDATION_ERRORS=0

    info "Running Docker Overrides Validator"
    # Check for the directory and files should this be used from the command line
    if [[ ! -d "${DOCKER_OVERRIDES_DIR}" ]]; then
        error "${DOCKER_OVERRIDES_DIR}/ does not exist. Create it and populate it with files to validate."
        return
    fi
    if [[ $(find ${DETECTED_HOMEDIR}/.config/docker_overrides/* -type f -not -name "original_overrides.yml" -prune | wc -l) -eq 0 ]]; then
        error "No YML files found in ${DOCKER_OVERRIDES_DIR}/ to validate."
        return
    fi
    info "Validating YML files in ${DOCKER_OVERRIDES_DIR}/"
    shopt -s dotglob
    while IFS= read -r path; do
        if [[ -f "${path}" ]]; then
            if yq-go v ${path} > /dev/null 2>&1; then
                info "${path//${DOCKER_OVERRIDES_DIR}\//} valid!"
            else
                error "${path//${DOCKER_OVERRIDES_DIR}\//} is not valid yml. See errors below."
                yq-go v ${path}
                VALIDATION_ERRORS=((VALIDATION_ERRORS + 1))
            fi
        fi
    done < <(find ${DOCKER_OVERRIDES_DIR}/* -type f -prune)
    shopt -u dotglob

    info "Validation complete."

    # TODO: Prompt user if ther are validation errors
    # if [[ ${VALIDATION_ERRORS} -gt 0 ]]; then

    # fi
}

test_docker_overrides_validate() {
    run_script 'docker_overrides_validate'
}
