#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=(
	find
)

env_backup() {
	local DOCKER_VOLUME_CONFIG
	# Update CONFIG_FOLDER and LITERAL_CONFIG_FOLDER based on DOCKER_CONFIG_FOLDER
	local DOCKER_CONFIG_FOLDER
	DOCKER_CONFIG_FOLDER="$(run_script 'env_get' DOCKER_CONFIG_FOLDER)"
	if [[ -z ${DOCKER_CONFIG_FOLDER-} ]]; then
		DOCKER_CONFIG_FOLDER="$(run_script 'var_default_value' DOCKER_CONFIG_FOLDER)"
	fi
	DOCKER_CONFIG_FOLDER="$(run_script 'sanitize_path' "${DOCKER_CONFIG_FOLDER}")"
	LITERAL_CONFIG_FOLDER="${DOCKER_CONFIG_FOLDER}"
	DOCKER_CONFIG_FOLDER="$(
		HOME="${HOME}" XDG_CONFIG_HOME="${XDG_CONFIG_HOME}" \
			eval echo "${LITERAL_CONFIG_FOLDER}"
	)"
	DOCKER_VOLUME_CONFIG="$(run_script 'env_get' DOCKER_VOLUME_CONFIG)"
	if [[ -z ${DOCKER_VOLUME_CONFIG-} ]]; then
		DOCKER_VOLUME_CONFIG="$(run_script 'env_get' DOCKERCONFDIR)"
	fi
	if [[ -z ${DOCKER_VOLUME_CONFIG-} ]]; then
		DOCKER_VOLUME_CONFIG="$(run_script 'var_default_value' DOCKER_VOLUME_CONFIG)"
		DOCKER_VOLUME_CONFIG="${DOCKER_VOLUME_CONFIG#[\"\']}"
		DOCKER_VOLUME_CONFIG="${DOCKER_VOLUME_CONFIG%[\"\']}"
	fi
	if [[ -z ${DOCKER_VOLUME_CONFIG-} ]]; then
		fatal \
			"Variable '{{|Var|}}DOCKER_VOLUME_CONFIG{{[-]}}' is not set in the '{{|File|}}.env{{[-]}}' file"
	fi
	DOCKER_VOLUME_CONFIG="$(
		HOME="${HOME}" XDG_CONFIG_HOME="${XDG_CONFIG_HOME}" DOCKER_CONFIG_FOLDER="${DOCKER_CONFIG_FOLDER-}" \
			eval echo "${DOCKER_VOLUME_CONFIG}"
	)"
	DOCKER_VOLUME_CONFIG="$(run_script 'sanitize_path' "${DOCKER_VOLUME_CONFIG}")"

	info "Taking ownership of '{{|Folder|}}${DOCKER_VOLUME_CONFIG}{{[-]}}' (non-recursive)."
	sudo chown "${DETECTED_PUID}":"${DETECTED_PGID}" "${DOCKER_VOLUME_CONFIG}" &> /dev/null || true

	local COMPOSE_BACKUPS_FOLDER="${DOCKER_VOLUME_CONFIG}/.compose.backups"
	local BACKUPTIME
	BACKUPTIME="$(date +"%Y%m%d.%H.%M.%S")"
	local BACKUP_FOLDER="${COMPOSE_BACKUPS_FOLDER}/${COMPOSE_FOLDER_NAME}.${BACKUPTIME}"

	local -a BackupList
	readarray -t BackupList < <(
		${FIND} "${COMPOSE_FOLDER}" -maxdepth 1 \
			\( \
			\( -type d \
			-name "${APP_ENV_FOLDER_NAME}" \
			\) -exec echo "{}/" \; \
			\) -o \
			\( -type f \( \
			-name "${COMPOSE_OVERRIDE_NAME}" -o \
			-name ".env" -o \
			-name ".env.app.*" \
			\) -exec echo "{}" \; \
			\) | sort 2> /dev/null || true
	)
	local Indent='\t'
	if [[ ${#BackupList[@]} -gt 0 ]]; then
		notice \
			"Backing up user files to folder:" \
			"\t{{|Folder|}}${BACKUP_FOLDER}{{[-]}}"
		info "Creating folder '{{|Folder|}}${BACKUP_FOLDER}{{[-]}}'"
		mkdir -p "${BACKUP_FOLDER}" ||
			fatal \
				"Failed to make directory." \
				"Failing command: {{|FailingCommand|}}mkdir -p \"${BACKUP_FOLDER}\""
		info \
			"Backing up files:" \
			"$(printf "${Indent}{{|File|}}%s{{[-]}}\n" "${BackupList[@]}")"
		cp -R "${BackupList[@]}" "${BACKUP_FOLDER}/" ||
			fatal \
				"Failed to copy file." \
				"Failing command: {{|FailingCommand|}}cp -R $(printf '"%s" ' "${BackupList[@]}") \"${BACKUP_FOLDER}/\""
	fi

	run_script 'set_permissions' "${COMPOSE_BACKUPS_FOLDER}"

	info "Removing old compose backups."
	${FIND} "${COMPOSE_BACKUPS_FOLDER}" -maxdepth 1 -type f -name ".env.*" -mtime +3 -delete &> /dev/null ||
		warn "Old .env backups not removed."
	${FIND} "${COMPOSE_BACKUPS_FOLDER}" -maxdepth 1 -type d -name "${COMPOSE_FOLDER_NAME}.*" -mtime +3 -exec rm -rf {} + &> /dev/null ||
		warn "Old compose backups not removed."

	# Backup location has moved
	if [[ -d "${DOCKER_VOLUME_CONFIG}/.env.backups" ]]; then
		info "Removing old backup location."
		rm -rf "${DOCKER_VOLUME_CONFIG}/.env.backups" ||
			fatal \
				"Failed to remove directory." \
				"Failing command: {{|FailingCommand|}}rm -rf \"${DOCKER_VOLUME_CONFIG}/.env.backups\""
	fi
}

test_env_backup() {
	run_script 'env_backup'
}
