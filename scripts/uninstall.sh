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

	local ds2_found=false
	if ds2_installed; then
		# Keep the templates folder
		local TemplatesFolder="${APPLICATION_STATE_FOLDER}/${TEMPLATES_PARENT_FOLDER_NAME}"
		ExcludePaths+=("${TemplatesFolder}")
		UninstallNotice+=(
			"{{|ApplicationName|}}DockSTARTer2{{[-]}} install detected. Keeping downloaded templates in '{{|Folder|}}${TemplatesFolder}{{[-]}}'."
			""
		)
		ds2_found=true
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

	while true; do
		hash -r
		local symlink
		symlink="$(command -v "${APPLICATION_COMMAND}" 2> /dev/null)" || break
		if [[ ! -L ${symlink} ]] || [[ "$(readlink -f "${symlink}")" != "${SCRIPTNAME}" ]]; then
			break
		fi
		notice "Removing {{|ApplicationName|}}${APPLICATION_NAME}{{[-]}} symlink '{{|File|}}${symlink}{{[-]}}'"
		sudo rm "${symlink}"
	done

	notice "Removing {{|ApplicationName|}}${APPLICATION_NAME}{{[-]}} scripts folder '{{|Folder|}}${SCRIPTPATH}{{[-]}}'"

	# Flush logs and exec into this script to remove the DockSTARTer script folder
	flush_logs
	exec bash "${BASH_SOURCE[0]}" "${ds2_found}" "${SCRIPTPATH}" "${ExcludeFindArgs[@]}"
}

ds2_installed() {
	# Return "true" if DockSTARTer2 is installed
	[[ -d "${XDG_STATE_HOME}/dockstarter2" ]]
}

test_uninstall() {
	warn "CI does not test uninstall."
}

uninstall_finalize() {
	local ds2_found=${1}
	local script_folder=${2}
	shift 2
	local -a ExcludeFindArgs=("$@")

	find "${script_folder}" -mindepth 1 -maxdepth 1 "${ExcludeFindArgs[@]}" -exec sudo rm -rf {} +
	sudo rmdir "${script_folder}" 2> /dev/null || true

	#shellcheck disable=SC2016 #(info): Expressions don't expand in single quotes, use double quotes for that.
	local -a message=(
		'DockSTARTer has been uninstalled.'
		''
		'To reinstall DockSTARTer, run the following command:'
		'\tbash -c "$(curl -fsSL https://get.dockstarter.com)"'
		''
	)
	if [[ ${ds2_found} == "true" ]]; then
		message+=(
			'DockSTARTer2 appears to be installed.'
			"To run DockSTARTer2, you can generally type 'ds2'."
		)
	else
		#shellcheck disable=SC2016 #(info): Expressions don't expand in single quotes, use double quotes for that.
		message+=(
			'To install DockSTARTer2, run the following command:'
			'\tsh -c "$(curl -fsSL https://getv2.dockstarter.com)"'
		)
	fi
	printf "%b\n" "${message[@]}"
}

[[ ${BASH_SOURCE[0]} == "${0}" ]] && uninstall_finalize "$@"
