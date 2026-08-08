#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

uninstall() {
	local Title="Uninstall"
	local Question="Do you want to uninstall {{|ApplicationName|}}${APPLICATION_NAME}{{[-]}}?"
	if ! run_script 'question_prompt' N "${Question}" "${Title}" "${ASSUMEYES:+Y}"; then
		notice "Not uninstalling {{|ApplicationName|}}${APPLICATION_NAME}{{[-]}}"
		return 0
	fi
	local -a UninstallNotice=(
		""
		"Uninstalling {{|ApplicationName|}}${APPLICATION_NAME}{{[-]}}"
		""
	)

	# Keep the compose and configuration folders
	local -a ExcludePaths=(
		"${APPLICATION_CONFIG_FOLDER}"
		"${COMPOSE_FOLDER}"
	)
	if [[ ${COMPOSE_FOLDER} != "${SCRIPTPATH}/compose" ]]; then
		ExcludePaths+=("${SCRIPTPATH}/compose")
	fi

	local DOCKER_VOLUME_CONFIG
	run_script 'env_get_into' DOCKER_VOLUME_CONFIG DOCKER_VOLUME_CONFIG
	DOCKER_VOLUME_CONFIG="$(
		expand_vars "${DOCKER_VOLUME_CONFIG}" \
			DOCKER_CONFIG_FOLDER "${CONFIG_FOLDER}" \
			HOME "${DETECTED_HOMEDIR}"
	)"
	if [[ -n ${DOCKER_VOLUME_CONFIG} ]]; then
		ExcludePaths+=("${DOCKER_VOLUME_CONFIG}")
	fi

	if ds2_installed; then
		# Keep the templates folder
		local TemplatesFolder="${APPLICATION_STATE_FOLDER}/${TEMPLATES_PARENT_FOLDER_NAME}"
		ExcludePaths+=("${TemplatesFolder}")
		UninstallNotice+=(
			"{{|ApplicationName|}}DockSTARTer2{{[-]}} install detected. Keeping downloaded templates in '{{|Folder|}}${TemplatesFolder}{{[-]}}'."
			""
		)
	fi

	for path_index in "${!ExcludePaths[@]}"; do
		local path="${ExcludePaths[path_index]}"
		if [[ ! -e ${path} ]]; then
			unset 'ExcludePaths[path_index]'
		fi
	done

	UninstallNotice+=(
		"Keeping:"
		"$(printf "\t'{{|Folder|}}%s{{[-]}}'\n" "${ExcludePaths[@]}")"
		""
	)

	notice "${UninstallNotice[@]}"

	# Delete the application state folder contents
	local -a ExcludeFindArgs=()
	for path in "${ExcludePaths[@]}"; do
		ExcludeFindArgs+=(-not -path "${path}")
	done

	if [[ -n ${APPLICATION_CACHE_FOLDER-} && -d ${APPLICATION_CACHE_FOLDER} ]]; then
		notice "Removing {{|ApplicationName|}}${APPLICATION_NAME}{{[-]}} cache folder '{{|Folder|}}${APPLICATION_CACHE_FOLDER}{{[-]}}'"
		sudo rm -rf "${APPLICATION_CACHE_FOLDER?}" &> /dev/null || true
	fi

	# Remove all files and folders in the application state folder, except the excluded paths
	notice "Removing {{|ApplicationName|}}${APPLICATION_NAME}{{[-]}} state folder '{{|Folder|}}${APPLICATION_STATE_FOLDER}{{[-]}}'"
	find "${APPLICATION_STATE_FOLDER}" -mindepth 1 -maxdepth 1 "${ExcludeFindArgs[@]}" -exec sudo rm -rf {} + || true

	# Remove the application state folder if it's empty
	sudo rmdir "${APPLICATION_STATE_FOLDER}" 2> /dev/null || true

	# Exec into this script to remove the DockSTARTer script folder
	notice "Removing {{|ApplicationName|}}${APPLICATION_NAME}{{[-]}} symlinks and script folder"

	flush_logs
	exec bash "${BASH_SOURCE[0]}" "${SCRIPTPATH}" "${SCRIPTNAME}" "${APPLICATION_COMMAND}" "${ExcludeFindArgs[@]}"
}

ds2_installed() {
	# Return "true" if DockSTARTer2 is installed
	[[ -d "${XDG_STATE_HOME}/dockstarter2" ]]
}

test_uninstall() {
	warn "CI does not test uninstall."
}

uninstall_finalize() {
	local script_folder=${1}
	local script=${2}
	local symlink_name=${3}
	shift 3
	local -a ExcludeFindArgs=("$@")
	while true; do
		hash -r
		local symlink
		symlink="$(command -v "${symlink_name}" 2> /dev/null)" || break
		if [[ ! -L ${symlink} ]] || [[ "$(readlink -f "${symlink}")" != "${script}" ]]; then
			break
		fi
		echo "Removing symlink: ${symlink}"
		sudo rm "${symlink}"
	done
	echo "Removing script folder: ${script_folder}"
	find "${script_folder}" -mindepth 1 -maxdepth 1 "${ExcludeFindArgs[@]}" -exec sudo rm -rf {} +
	sudo rmdir "${script_folder}" 2> /dev/null || true
	echo "DockSTARTer has been uninstalled."
}

[[ ${BASH_SOURCE[0]} == "${0}" ]] && uninstall_finalize "$@"
