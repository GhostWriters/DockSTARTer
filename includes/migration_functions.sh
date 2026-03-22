#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

MigrateFilesAndFolders() {
	local -A MigrationFileMap=(
		["${SCRIPTPATH}/dockstarter.log"]="${APPLICATION_LOG}"
		["${APPLICATION_STATE_FOLDER}/fatal.log"]="${FATAL_LOG}"
		["${SCRIPTPATH}/fatal.log"]="${FATAL_LOG}"
	)

	local -A MigrationFolderMap=(
		["${APPLICATION_STATE_FOLDER}/.theme"]="${THEME_FOLDER}"
		["${APPLICATION_STATE_FOLDER}/.timestamps"]="${TIMESTAMPS_FOLDER}"
		["${APPLICATION_STATE_FOLDER}/.instances"]="${INSTANCES_FOLDER}"
	)

	for OldFile in "${!MigrationFileMap[@]}"; do
		local NewFile="${MigrationFileMap[${OldFile}]}"

		if [[ ! -f ${NewFile} && -f ${OldFile} ]]; then
			warn "Migrating '{{|File|}}${OldFile}{{[-]}}' to '{{|File|}}${NewFile}{{[-]}}'."
			RunAndLog warn "mv:warn" \
				warn "Failed to migrate '{{|File|}}${OldFile}{{[-]}}'." \
				mv "${OldFile}" "${NewFile}" || true
		fi
	done

	for OldFolder in "${!MigrationFolderMap[@]}"; do
		local NewFolder="${MigrationFolderMap[${OldFolder}]}"

		if [[ ! -d ${NewFolder} && -d ${OldFolder} ]]; then
			warn "Migrating '{{|Folder|}}${OldFolder}{{[-]}}' to '{{|Folder|}}${NewFolder}{{[-]}}'."
			RunAndLog warn "mv:warn" \
				warn "Failed to migrate '{{|Folder|}}${OldFolder}{{[-]}}'." \
				mv "${OldFolder}" "${NewFolder}" || true
		fi
	done
}
