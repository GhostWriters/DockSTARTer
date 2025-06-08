#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

env_backup() {
    local DOCKER_VOLUME_CONFIG
    DOCKER_VOLUME_CONFIG="$(run_script 'env_get' DOCKER_VOLUME_CONFIG)"
    if [[ -z ${DOCKER_VOLUME_CONFIG-} ]]; then
        DOCKER_VOLUME_CONFIG="$(run_script 'env_get' DOCKERCONFDIR)"
    fi
    if [[ -z ${DOCKER_VOLUME_CONFIG-} ]]; then
        DOCKER_VOLUME_CONFIG="$(run_script 'var_default_value' DOCKER_VOLUME_CONFIG)"
        run_script 'env_set_literal' DOCKER_VOLUME_CONFIG "${DOCKER_VOLUME_CONFIG}"
        DOCKER_VOLUME_CONFIG="$(run_script 'env_get' DOCKER_VOLUME_CONFIG)"
    fi
    if [[ -z ${DOCKER_VOLUME_CONFIG-} ]]; then
        warn "Can't back up settings, variable DOCKER_VOLUME_CONFIG is not set in the .env file"
        return
    fi
    info "Taking ownership of ${DOCKER_VOLUME_CONFIG} (non-recursive)."
    sudo chown "${DETECTED_PUID}":"${DETECTED_PGID}" "${DOCKER_VOLUME_CONFIG}" > /dev/null 2>&1 || true

    local COMPOSE_BACKUPS_FOLDER="${DOCKER_VOLUME_CONFIG}/.compose.backups"
    local BACKUPTIME
    BACKUPTIME="$(date +"%Y%m%d%H%M%S")"
    local BACKUP_FOLDER="${COMPOSE_BACKUPS_FOLDER}/${COMPOSE_FOLDER_NAME}.${BACKUPTIME}"

    info "Copying .env file to ${BACKUP_FOLDER}/.env"
    mkdir -p "${BACKUP_FOLDER}" ||
        fatal "Failed to make directory.\nFailing command: ${F[C]}mkdir -p \"${BACKUP_FOLDER}\""
    cp "${COMPOSE_ENV}" "${BACKUP_FOLDER}/" ||
        fatal "Failed to copy backup.\nFailing command: ${F[C]}cp \"${COMPOSE_ENV}\" \"${BACKUP_FOLDER}/\""

    info "Copying appplication env folder to ${BACKUP_FOLDER}/${APP_ENV_FOLDER_NAME}"
    cp -r "${APP_ENV_FOLDER}" "${BACKUP_FOLDER}/" ||
        fatal "Failed to copy backup.\nFailing command: ${F[C]}cp -r \"${APP_ENV_FOLDER}\" \"${BACKUP_FOLDER}/\""

    if [[ -f ${COMPOSE_OVERRIDE} ]]; then
        info "Copying override file to ${BACKUP_FOLDER}/${COMPOSE_OVERRIDE_NAME}"
        cp "${COMPOSE_OVERRIDE}" "${BACKUP_FOLDER}/" ||
            fatal "Failed to copy backup.\nFailing command: ${F[C]}cp \"${COMPOSE_OVERRIDE}\" \"${BACKUP_FOLDER}/\""
    fi

    run_script 'set_permissions' "${COMPOSE_BACKUPS_FOLDER}"

    info "Removing old compose backups."
    find "${COMPOSE_BACKUPS_FOLDER}" -type f -name ".env.*" -mtime +3 -delete > /dev/null 2>&1 ||
        warn "Old .env backups not removed."
    find "${COMPOSE_BACKUPS_FOLDER}" -type d -name "${COMPOSE_FOLDER_NAME}.*" -mtime +3 -prune -exec rm -rf {} + > /dev/null 2>&1 ||
        warn "Old compose backups not removed."

    # Backup location has moved
    if [[ -d "${DOCKER_VOLUME_CONFIG}/.env.backups" ]]; then
        info "Removing old backup location."
        rm -rf "${DOCKER_VOLUME_CONFIG}/.env.backups" ||
            fatal "Failed to remove directory.\nFailing command: ${F[C]}rm -rf \"${DOCKER_VOLUME_CONFIG}/.env.backups\""
    fi
}

test_env_backup() {
    run_script 'env_backup'
}
